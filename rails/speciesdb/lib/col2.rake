require 'pp'

namespace :col2 do
  
  DATABASE = "col2015ac"

  desc %{list COL kingdoms}
  task :list, [:taxon_id] => :environment do |t, args|
    connection = ActiveRecord::Base.connection
    if args[:taxon_id].present?
      cond = " = #{args[:taxon_id]}"
    else
      cond = " is null"
    end
    result = connection.execute("select s.name_element, tne.taxon_id, tr.rank " + 
          "from #{DATABASE}.scientific_name_element s, #{DATABASE}.taxon_name_element tne " +
          ", #{DATABASE}.taxon t, #{DATABASE}.taxonomic_rank tr " + 
                       "where s.id = tne.scientific_name_element_id and tne.parent_id #{cond} " +
                       "and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id")
    puts result.class.name                   
    
    result.each do | r |
      pp r
    end

  end
  
    
  desc %{import the top level taxa from COL}
  task :import_top_levels => :environment do |t, args|

    connection = ActiveRecord::Base.connection
    result = connection.execute("select s.name_element, tne.taxon_id, tr.rank " + 
          "from #{DATABASE}.scientific_name_element s, #{DATABASE}.taxon_name_element tne " +
          ", #{DATABASE}.taxon t, #{DATABASE}.taxonomic_rank tr " + 
                       "where s.id = tne.scientific_name_element_id  and tne.parent_id is null " +
                       "and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id ")                  
    
    result.each do | r |
      taxon_scientific_name = r[0]
      taxon_id = r[1]
      rank = r[2]
      puts "#{rank} #{taxon_scientific_name} #{taxon_id}"
      taxon = new_taxon(taxon_scientific_name, taxon_id, rank)
      taxon.taxonomy = Taxonomy.find_or_initialize_by(slug: 'col') do |t|
      t.names << Name.new(name: "Catalogue of Life", language_iso: "eng")
    end
      taxon.save
    end

  end

  # importerer alle taxa ned til artsnivå
  # bare arter med 
  # Kan f eks kalle denne slik for å importere alle ryggstrengdyr:
  # $ rake col:import[22032976]
  #
  # men må først ha kjørt:
  # $ rake col:import_top_levels
  
  desc %{import data from COL, parent must exist}
  task :import, [:taxon_id] => :environment do |t, args|

    puts args[:taxon_id]


    connection = ActiveRecord::Base.connection
    result = connection.execute("select s.name_element, tne.taxon_id, tr.rank, tne.parent_id " + 
          "from #{DATABASE}.scientific_name_element s, #{DATABASE}.taxon_name_element tne " +
          ", #{DATABASE}.taxon t, #{DATABASE}.taxonomic_rank tr " + 
                       "where s.id = tne.scientific_name_element_id  " +
                       "and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id and t.id = #{args[:taxon_id]}")
                       
    result.each do | r |
      taxon_scientific_name = r[0]
      taxon_id = r[1]
      rank = r[2]
      parent_id = r[3]
      #puts taxon_scientific_name
      parent = Taxon.where('col_taxon_id = ?', parent_id).first
      t = new_taxon(taxon_scientific_name, taxon_id, rank, parent)
      get_taxon("#{rank} #{taxon_scientific_name}", t, connection)
    end

  end
  
  def new_taxon(taxon_scientific_name, taxon_id, rank, parent = nil)
      taxon = Taxon.find_or_initialize_by(col_taxon_id: taxon_id, taxon_scientific_name: taxon_scientific_name)
      taxon.parent = parent
      taxon.taxonomy = parent.taxonomy unless parent.nil?
      if taxon.ranks.empty?
        taxon.ranks << Rank.find_or_create_by(language_iso: "eng", rank: rank)
      end
      # t = Taxon.new(scientific_name: scientific_name, col_taxon_id: taxon_id, parent: parent)
      # t.ranks << Rank.new(rank: rank, language_iso: "eng")
      taxon
  end
  
  def get_taxon(parent_str, parent, connection)
    puts parent_str
    result = connection.execute("select s.name_element, tne.taxon_id, tr.rank " + 
          "from #{DATABASE}.scientific_name_element s, #{DATABASE}.taxon_name_element tne " +
          ", #{DATABASE}.taxon t, #{DATABASE}.taxonomic_rank tr " + 
                       "where s.id = tne.scientific_name_element_id and tne.parent_id = #{parent.col_taxon_id} " +
                       "and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id")
    result.each do | r |
      taxon_scientific_name = r[0]
      puts parent_str + " " + taxon_scientific_name
      taxon_id = r[1]
      rank = r[2]
      #if rank == "species"
      #puts "rank:" + rank
       if ["subspecies", "species", "not assigned"].include? rank
         english_name = get_english_name(taxon_id)
         if english_name.present?
           if rank == "species"
             t = Species.find_or_initialize_by(col_taxon_id: taxon_id, taxon_scientific_name: taxon_scientific_name)
           elsif rank == "subspecies" or rank == "not assigned"
             t = SubSpecies.find_or_initialize_by(col_taxon_id: taxon_id, taxon_scientific_name: taxon_scientific_name)
           end             
           t.parent = parent
           t.taxonomy = parent.taxonomy
           if t.common_names.select {|name| name.language_iso == "eng"}.empty?
             t.common_names << Name.new(name: english_name, language_iso: "eng")
           else
             name = t.common_names.select {|name| name.language_iso == "eng"}.first
             name.update_column(:name, english_name)
           end
           t.slug = t.scientific_name.parameterize
           t.ranks = [Rank.find_or_create_by(rank: rank, language_iso: "eng")] 
           t.save
           #puts "Saved one species, will exit"
           
           #exit
           if rank == "species"
             get_taxon("#{parent_str} #{rank} #{taxon_scientific_name}", t, connection)
           # else
           #   puts "subspecies or not assigned: %s %s" % [parent_str, t.scientific_name]
           #   # for testing: exit after the first subspecies
           #   exit
           end
           # if rank == "not assigned" or "subspecies", we will not go any further down in the taxonomy
         end
       else
         unless rank == "not assigned"
           puts taxon_scientific_name
           if taxon_scientific_name == "reptilia" or parent.taxon_scientific_name == "reptilia" or parent.parent.taxon_scientific_name == "reptilia"
             t = new_taxon(taxon_scientific_name, taxon_id, rank, parent)
           # calls the method recursively to get the children of this taxon
             get_taxon("#{parent_str} #{rank} #{taxon_scientific_name}", t, connection)
             exit
           end
         end
       end
    end       
  end
  
  def get_english_name(taxon_id)
    result = ActiveRecord::Base.connection.execute("select name " + 
          "from #{DATABASE}.common_name cn, #{DATABASE}.common_name_element cne " +
                       "where cn.taxon_id = #{taxon_id} " +
                       "and cn.common_name_element_id = cne.id and cn.language_iso = 'eng'")
    return (result.count == 0) ? nil : result.first[0]
  end
  
end
