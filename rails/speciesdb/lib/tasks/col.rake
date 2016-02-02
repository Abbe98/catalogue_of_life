require 'pp'

namespace :col do
  
  DATABASE = "col2015ac"
  COL_VERSION = "2015 Annual Checklist"
  

  desc %{list one level in the COL taxonomy. If taxon_id is not present, top level will be listed}
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
    
    result.each do | r |
      pp r
    end

  end
  
    
  desc %{import the top level taxa from COL}
  task :import_top_levels => :environment do |t, args|

    connection = ActiveRecord::Base.connection
    result = connection.execute("select s.name_element, tne.taxon_id, tr.rank, t.source_database_id " + 
          "from #{DATABASE}.scientific_name_element s, #{DATABASE}.taxon_name_element tne " +
          ", #{DATABASE}.taxon t, #{DATABASE}.taxonomic_rank tr " + 
                       "where s.id = tne.scientific_name_element_id  and tne.parent_id is null " +
                       "and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id " + 
                       "and s.name_element in ('animalia', 'plantae', 'fungi')")                  
    
    result.each do | r |
      taxon_scientific_name = r[0]
      taxon_id = r[1]
      rank = r[2]
      source_database_id = r[3]
      puts "%i: %s (%s)" % [taxon_id,taxon_scientific_name, rank]
      taxon = new_taxon(taxon_scientific_name, taxon_id, rank, nil, source_database_id)
      
      taxon.taxonomy = Taxonomy.find_by(slug: 'col')
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
  
  desc %{import data from COL, parent must exist, if children = "true", add children recursively}
  task :import, [:taxon_id,:children] => :environment do |t, args|
    
    parent_id = args[:taxon_id]
    puts "parent id: #{parent_id}" 
    
    count = 0

    connection = ActiveRecord::Base.connection
    result = connection.execute("select s.name_element, tne.taxon_id, tr.rank, t.source_database_id " + 
          "from #{DATABASE}.scientific_name_element s, #{DATABASE}.taxon_name_element tne " +
          ", #{DATABASE}.taxon t, #{DATABASE}.taxonomic_rank tr " + 
                       "where s.id = tne.scientific_name_element_id  " +
                       "and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id and tne.parent_id = #{args[:taxon_id]} " +
                       "order by s.name_element")
                       
    result.each do | r |
      taxon_scientific_name = r[0]
      taxon_id = r[1]
      rank = r[2]
      source_database_id = r[3]
      puts "%i: %s (%s)" % [taxon_id, taxon_scientific_name, rank]
      parent = Taxon.where('col_taxon_id = ?', parent_id).first
      if parent.nil?
        puts "parent not found"
        exit
      end
      #pp parent
      t = new_taxon(taxon_scientific_name, taxon_id, rank, parent, source_database_id)
      #puts "parent: %i" % t.parent_id
      if args[:children].present? && (args[:children] == "true")
        get_children("#{rank} #{taxon_scientific_name}", t, connection, true, count)
      end
      t.taxonomy = Taxonomy.find_by(slug: 'col')
      results = t.save
      #puts "task :import, save: %s" % results
      #puts "parent: %i" % t.parent_id
    end

  end
  
  def new_taxon(taxon_scientific_name, taxon_id, rank, parent, source_database_id)
      taxon = Taxon.find_or_initialize_by(col_taxon_id: taxon_id, taxon_scientific_name: taxon_scientific_name)
      taxon.parent = parent

      # slug will not be unique on all levels anyway, many has "not assigned"
      #taxon.slug = taxon.scientific_name.parameterize
      taxon.taxonomy = parent.taxonomy unless parent.nil?
      if taxon.ranks.empty?
        taxon.ranks << Rank.find_or_create_by(language_iso: "eng", rank: rank)
      end
      
      # add source database
      taxon.source_database = get_source_database_if_exists(taxon_id)
      taxon
  end
  
  def get_children(parent_str, parent, connection, deep, count)
    result = connection.execute("select s.name_element, tne.taxon_id, tr.rank, t.source_database_id  " + 
          "from #{DATABASE}.scientific_name_element s, #{DATABASE}.taxon_name_element tne " +
          ", #{DATABASE}.taxon t, #{DATABASE}.taxonomic_rank tr " + 
                       "where s.id = tne.scientific_name_element_id and tne.parent_id = #{parent.col_taxon_id} " +
                       "and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id")

    source = Source.find_or_initialize_by(slug: 'col') do |s|
     s.name =  "Catalogue of Life"
     s.version = COL_VERSION
    end
    
    result.each do | r |
      taxon_scientific_name = r[0]
      taxon_id = r[1]
      rank = r[2]
      source_database_id = r[3]
      #puts taxon_id
      #if rank == "species"
      #puts "rank:" + rank
      #puts SPECIES_AND_INFRASPECIFIC_RANKS.include? rank
      # if at the level of species or below:
       if SPECIES_AND_INFRASPECIFIC_RANKS.include? rank
         puts "will create a species or subspecies"
   ###      english_name = get_english_name(taxon_id)
   ###       if english_name.present?
           #puts "has english name"
           if rank == "species"
             t = Species.find_or_initialize_by(col_taxon_id: taxon_id, taxon_scientific_name: taxon_scientific_name)
           elsif INFRASPECIFIC_RANKS.include? rank
             t = Infraspecific.find_or_initialize_by(col_taxon_id: taxon_id, taxon_scientific_name: taxon_scientific_name)
           end             
           t.parent = parent
           t.taxonomy = parent.taxonomy
           t.slug = t.scientific_name.parameterize
           t.ranks = [Rank.find_or_create_by(rank: rank, language_iso: "eng")] 
           names = get_common_names(taxon_id)
           t.common_names.delete
           names.each do |name|
             # found some names with language_iso = "enc", must by a typo, so change to "eng"
             the_name = name[0]
             language_iso = (name[1] == "enc") ? "eng" : name[1]
             country_iso = name[2]
             t.common_names << Name.new(name: the_name, language_iso: language_iso, 
                                          country_iso: country_iso, source: source)

           end

           t.source_database = get_source_database_if_exists(source_database_id)
                      
           begin
             result = t.save
             puts "saved %s: %s" % [t.class.name, result]
             puts
             unless t.save 
               ErrorLog.create(message: t.errors.inspect)
             end
           rescue ActiveRecord::RecordNotUnique => e
              puts e.message
              result = ErrorLog.create(message: e.message)
              puts result
           end             
             
           puts t.scientific_name
           #exit if t.is_a? Infraspecific

           
           if rank == "species"
             if deep
               get_children("#{parent_str} #{rank} #{taxon_scientific_name}", t, connection, deep, count)
             end
           end
       else
         #unless rank == "not assigned"
           t = new_taxon(taxon_scientific_name, taxon_id, rank, parent, source_database_id)
           # calls the method recursively to get the children of this taxon
           if deep
             get_children("#{parent_str} #{rank} #{taxon_scientific_name}", t, connection, deep, count)
           end
           #end
       end
    end       
  end
  
  # looks like some species have language_iso = 'enc', while it should be 'eng'...
  # def get_english_name(taxon_id)
  #   result = ActiveRecord::Base.connection.execute("select name " +
  #         "from #{DATABASE}.common_name cn, #{DATABASE}.common_name_element cne " +
  #                      "where cn.taxon_id = #{taxon_id} " +
  #                      "and cn.common_name_element_id = cne.id and cn.language_iso in ('eng', 'enc')")
  #   return (result.count == 0) ? nil : result.first[0]
  # end
  
  def get_common_names(taxon_id)
    results = ActiveRecord::Base.connection.execute("select name, language_iso, country_iso " + 
          "from #{DATABASE}.common_name cn, #{DATABASE}.common_name_element cne " +
                       "where cn.taxon_id = #{taxon_id} " +
                       "and cn.common_name_element_id = cne.id")
    return (results.count == 0) ? [] : results
  end
  
  # 22141677
  def get_source_database_if_exists(source_database_id)
    return nil if source_database_id.nil?
    sql = "select sd.name, sd.authors_and_editors, uri.resource_identifier, us.scheme  " + 
          "from #{DATABASE}.source_database sd, #{DATABASE}.uri_to_source_database usd, #{DATABASE}.uri, " +
                       "#{DATABASE}.uri_scheme us " +
                       "where sd.id = #{source_database_id} " +
                       "and usd.source_database_id = sd.id and usd.uri_id = uri.id " +
                       "and us.id = uri.uri_scheme_id"
    #puts sql
    # select sd.name, sd.authors_and_editors, uri.resource_identifier, us.scheme
 #    from col2015ac.source_database sd, col2015ac.uri_to_source_database usd, col2015ac.uri, col2015ac.uri_scheme us
 #    where sd.id = 57 and usd.source_database_id = sd.id and usd.uri_id = uri.id and us.id = uri.uri_scheme_id;
    results = ActiveRecord::Base.connection.execute(sql)
    if results.count == 0
      return nil
    else
      sdb = results.first
      source_database = SourceDatabase.find_or_initialize_by(name: sdb[0], authors_and_editors: sdb[1]) do |s|
        s.uri = sdb[2]
        s.uri_scheme = sdb[3]
      end
    return source_database
   end
  end
    

  
end
