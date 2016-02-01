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
      puts "#{rank} #{taxon_scientific_name} #{taxon_id}"
      taxon = new_taxon(taxon_scientific_name, taxon_id, rank, nil, source_database_id)
      
      source = Source.find_or_initialize_by(slug: 'col') do |s|
        s.name =  "Catalogue of Life"
        s.version = COL_VERSION
      end
      taxon.taxonomy = Taxonomy.find_or_initialize_by(slug: 'col') do |t|
        t.product_name = "Species 2000 & ITIS Catalogue of Life: 2013 Annual Checklist"
        t.names << Name.new(name: "Catalogue of Life", language_iso: "eng", source: source)
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
  
  desc %{import data from COL, parent must exist, if children = "true", add children recursively}
  task :import, [:taxon_id,:children] => :environment do |t, args|

    puts "parent id: " + args[:taxon_id]
    
    count = 0

    connection = ActiveRecord::Base.connection
    result = connection.execute("select s.name_element, tne.taxon_id, tr.rank, tne.parent_id, t.source_database_id " + 
          "from #{DATABASE}.scientific_name_element s, #{DATABASE}.taxon_name_element tne " +
          ", #{DATABASE}.taxon t, #{DATABASE}.taxonomic_rank tr " + 
                       "where s.id = tne.scientific_name_element_id  " +
                       "and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id and tne.parent_id = #{args[:taxon_id]} " +
                       "order by s.name_element")
                       
    result.each do | r |
      taxon_scientific_name = r[0]
      taxon_id = r[1]
      rank = r[2]
      parent_id = r[3]
      source_database_id = r[4]
      puts "%i: %s" % [taxon_id,taxon_scientific_name]
      parent = Taxon.where('col_taxon_id = ?', parent_id).first
      t = new_taxon(taxon_scientific_name, taxon_id, rank, parent, source_database_id)
      get_children("#{rank} #{taxon_scientific_name}", t, connection, (args[:children].present? && args[:children] == "true"), count)
      results = t.save
      #puts "task :import, save: %s" % results
    end

  end
  
  def new_taxon(taxon_scientific_name, taxon_id, rank, parent, source_database_id)
      taxon = Taxon.find_or_initialize_by(col_taxon_id: taxon_id, taxon_scientific_name: taxon_scientific_name)
      taxon.parent = parent
      # this will not be unique on all levels anyway, many has "not assigned"
      #taxon.slug = taxon.scientific_name.parameterize
      taxon.taxonomy = parent.taxonomy unless parent.nil?
      if taxon.ranks.empty?
        taxon.ranks << Rank.find_or_create_by(language_iso: "eng", rank: rank)
      end
      
      # add source database
      source_database_fields = get_source_database_if_exists(taxon_id)
      #pp source_database_fields
      
      # t = Taxon.new(scientific_name: scientific_name, col_taxon_id: taxon_id, parent: parent)
      # t.ranks << Rank.new(rank: rank, language_iso: "eng")
      #puts taxon.taxonomic_ranks.inspect
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
      #puts ["subspecies", "species", "not assigned"].include? rank
      # if at the level of species or below:
       if SPECIES_AND_INFRASPECIFIC_RANKS.include? rank
         #puts "will create a species or subspecies"
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
     ###      if t.common_names.select {|name| name.language_iso == "eng"}.empty?
    ###         t.common_names << Name.new(name: english_name, language_iso: "eng")
    ###       else
    ###         name = t.common_names.select {|name| name.language_iso == "eng"}.first
    ###         name.update_column(:name, english_name)
    ###       end
           t.slug = t.scientific_name.parameterize
           t.ranks = [Rank.find_or_create_by(rank: rank, language_iso: "eng")] 
           #puts t.class.name
           names = get_common_names(taxon_id)
           #t.common_names.delete

           # names.each do |name|
           #   puts name.inspect
           # end
           t.common_names.delete
           names.each do |name|
             # found some names with language_iso = "enc", must by a typo, so change to "eng"
             the_name = name[0]
             language_iso = (name[1] == "enc") ? "eng" : name[1]
             country_iso = name[2]
             # check if name exists already. If it does, then update: 
             #common_names = t.common_names.select {|name| (name.language_iso == language_iso && name == the_name)}
             #if common_names.empty?
               t.common_names << Name.new(name: the_name, language_iso: language_iso, 
                                          country_iso: country_iso, source: source)
               #else
               #common_names.first.update_column(:name, the_name)
               #end
           end

           sdb = get_source_database_if_exists(source_database_id)
           t.source_database = SourceDatabase.find_or_initialize_by(name: sdb[0], authors_and_editors: sdb[1]) do |s|
              s.uri = sdb[2]
              s.uri_scheme = sdb[3]
           #
           # #s.name =  "Catalogue of Life"
           # #s.version = COL_VERSION
           end
                      
           begin
             unless t.save 
               ErrorLog.create(message: t.errors.inspect)
             end
           rescue ActiveRecord::RecordNotUnique => e
              puts e.message
              result = ErrorLog.create(message: e.message)
              puts result
           end             
             
           
           puts t.scientific_name

           
           # for testing, exit after the first species that have a common name: 
           #exit unless names.count == 0
           
           
           if rank == "species"
             if deep
               get_children("#{parent_str} #{rank} #{taxon_scientific_name}", t, connection, deep, count)
             end
           # else
           #   puts "subspecies or not assigned: %s %s" % [parent_str, t.scientific_name]
           #   # for testing: exit after the first subspecies
           #   exit
           end
           # if rank == "not assigned" or "subspecies", we will not go any further down in the taxonomy
      ###   else
           #puts "does NOT have english name: taxon_id: %i" % taxon_id
      ###   end
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
    return [] if source_database_id.nil?
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
    #puts results.count
    return (results.count == 0) ? [] : results.first
  end
    

  
end
