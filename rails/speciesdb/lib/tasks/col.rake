require 'pp'

namespace :col do
  
  DATABASE = "col2015ac"

  desc %{list COL kingdoms}
  task :list, [] => :environment do |t, args|
    connection = ActiveRecord::Base.connection
    result = connection.execute("select s.name_element, tne.taxon_id, tr.rank " + 
          "from #{DATABASE}.scientific_name_element s, #{DATABASE}.taxon_name_element tne " +
          ", #{DATABASE}.taxon t, #{DATABASE}.taxonomic_rank tr " + 
                       "where s.id = tne.scientific_name_element_id and tne.parent_id is null " +
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
      
      parent = Taxon.where('col_taxon_id = ?', parent_id).first
      t = new_taxon(taxon_scientific_name, taxon_id, rank, parent)
      get_taxon("#{rank} #{taxon_scientific_name}", t, connection)
    end

  end
  
  def new_taxon(taxon_scientific_name, taxon_id, rank, parent = nil)
      taxon = Taxon.find_or_initialize_by(col_taxon_id: taxon_id, taxon_scientific_name: taxon_scientific_name)
      taxon.parent = parent
      if taxon.ranks.empty?
        taxon.ranks << Rank.find_or_create_by(language_iso: "eng", rank: rank)
      end
      # t = Taxon.new(scientific_name: scientific_name, col_taxon_id: taxon_id, parent: parent)
      # t.ranks << Rank.new(rank: rank, language_iso: "eng")
      taxon
  end
  
  def get_taxon(parent_str, parent, connection)
    result = connection.execute("select s.name_element, tne.taxon_id, tr.rank " + 
          "from #{DATABASE}.scientific_name_element s, #{DATABASE}.taxon_name_element tne " +
          ", #{DATABASE}.taxon t, #{DATABASE}.taxonomic_rank tr " + 
                       "where s.id = tne.scientific_name_element_id and tne.parent_id = #{parent.col_taxon_id} " +
                       "and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id")
    result.each do | r |
      taxon_scientific_name = r[0]
      taxon_id = r[1]
      rank = r[2]
      
      #if rank == "species"
       if rank == "species"
         english_name = get_english_name(taxon_id)
         if english_name.present?
           s = Species.find_or_initialize_by(col_taxon_id: taxon_id)
           s.taxon_scientific_name = taxon_scientific_name
           s.parent = parent
           if s.common_names.select {|name| name.language_iso == "eng"}.empty?
             s.common_names << Name.new(name: english_name, language_iso: "eng")
           else
             name = s.common_names.select {|name| name.language_iso == "eng"}.first
             name.update_column(:name, english_name)
           end
           s.slug = s.binomial_name.parameterize
           s.ranks = [Rank.find_or_create_by(rank: rank, language_iso: "eng")] 
           s.save
           #puts "Saved one species, will exit"
           puts s.scientific_name
           
           exit
         end
       else
         t = new_taxon(taxon_scientific_name, taxon_id, rank, parent)
         # calls the method recursively to get the children of this taxon
         get_taxon("#{parent_str} #{rank} #{taxon_scientific_name}", t, connection)
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
