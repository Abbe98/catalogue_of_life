# catalogue_of_life

## prerequisites
Install Vagrant and VirtualBox. 

## install

    $ git clone https://github.com/Biocaching/catalogue_of_life.git
    $ cd catalogue_of_life
    $ vagrant up

After this, Catalogue of Life: 2015 Annual Checklist will be installed and available at http://192.168.33.8/col2015ac/

## database
To browse the database: 

    $ vagrant ssh
    $ cd /vagrant/sql
    [vagrant@localhost ~]$ mysql -u root col2015ac
    Reading table information for completion of table and column names
    You can turn off this feature to get a quicker startup with -A
    
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 31
    Server version: 10.1.9-MariaDB MariaDB Server
    
    Copyright (c) 2000, 2015, Oracle, MariaDB Corporation Ab and others.
    
    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
    
    MariaDB [col2015ac]> show tables;
    +---------------------------------------+
    | Tables_in_col2015ac                   |
    +---------------------------------------+
    | _natural_keys                         |
    | _search_all                           |
    | _search_distribution                  |
    | _search_family                        |
    | _search_scientific                    |
    | _source_database_details              |
    | _source_database_to_taxon_tree_branch |
    | _species_details                      |
    | _taxon_tree                           |
    | _totals                               |
    | author_string                         |
    | common_name                           |
    | common_name_element                   |
    | country                               |
    | distribution                          |
    | distribution_free_text                |
    | distribution_status                   |
    | hybrid                                |
    | language                              |
    | lifezone                              |
    | lifezone_to_taxon_detail              |
    | reference                             |
    | reference_to_common_name              |
    | reference_to_synonym                  |
    | reference_to_taxon                    |
    | reference_type                        |
    | region                                |
    | region_free_text                      |
    | region_standard                       |
    | scientific_name_element               |
    | scientific_name_status                |
    | scrutiny                              |
    | source_database                       |
    | specialist                            |
    | synonym                               |
    | synonym_name_element                  |
    | taxon                                 |
    | taxon_detail                          |
    | taxon_name_element                    |
    | taxonomic_coverage                    |
    | taxonomic_rank                        |
    | uri                                   |
    | uri_scheme                            |
    | uri_to_source_database                |
    | uri_to_taxon                          |
    +---------------------------------------+
    45 rows in set (0.00 sec)
    
    MariaDB [col2015ac]>  source top_level.sql
    +--------------+
    | name_element |
    +--------------+
    | animalia     |
    | plantae      |
    | fungi        |
    | viruses      |
    | bacteria     |
    | chromista    |
    | protozoa     |
    | archaea      |
    +--------------+
    8 rows in set (0.00 sec)
    
    MariaDB [col2015ac]> 
    
    Alle i dyreriket: 
    MariaDB [col2015ac]>  source animalia.sql
    
    Alle i chordata: 
    MariaDB [col2015ac]>  source chordata.sql
    
    Alle i chordata: 
    MariaDB [col2015ac]>  source chordata.sql
    
    Alle pattedyr:
    MariaDB [col2015ac]>  source mammalia.sql
    
    Alle rodyr (kjøttetere):
    MariaDB [col2015ac]>  source carnivora.sql
    
    Alle arter i bjørnefamilien: 
    MariaDB [col2015ac]>  source ursus.sql
     
    Alle underarter av nordamerikansk bjørn:
    
    MariaDB [col2015ac]>  source americanus.sql
    

### Finne navn på art: 

    MariaDB [col2015ac]> select * from common_name cn, common_name_element cne where cn.taxon_id  = 21936335 and cn.common_name_element_id = cne.id;
    +------+----------+------------------------+--------------+-------------+---------------------+------+------------+-----------------+
    | id   | taxon_id | common_name_element_id | language_iso | country_iso | region_free_text_id | id   | name       | transliteration |
    +------+----------+------------------------+--------------+-------------+---------------------+------+------------+-----------------+
    | 1866 | 21936335 |                   1864 | fra          | NULL        |                NULL | 1864 | ours blanc | NULL            |
    | 1867 | 21936335 |                   1865 | eng          | NULL        |                NULL | 1865 | Polar Bear | NULL            |
    +------+----------+------------------------+--------------+-------------+---------------------+------+------------+-----------------+
    2 rows in set (0.00 sec)
    


Gorilla:

    select * from common_name, common_name_element, taxon, taxonomic_rank, scientific_name_element, taxon_name_element 
      where name like '%gorilla%' 
        and common_name.common_name_element_id = common_name_element.id
        and taxon.id = common_name.taxon_id 
        and scientific_name_element.id = taxon_name_element.scientific_name_element_id
        and taxonomic_rank.id = taxon.taxonomic_rank_id
        and taxon_name_element.taxon_id = taxon.id;


Arter i løvetannfamilien: 

    select s.name_element, tne.taxon_id, tr.rank from scientific_name_element s, taxon_name_element tne, taxon t, taxonomic_rank tr where s.id = tne.scientific_name_element_id and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id and tne.parent_id = 22102505 order by s.name_element;
        

Funker ikke: 

    select s.name_element, tne.taxon_id, tr.rank 
      from scientific_name_element s, taxon_name_element tne, taxon t, taxonomic_rank tr, common_name cn, common_name_element cne 
      where s.id = tne.scientific_name_element_id and t.id = tne.taxon_id and tr.id = t.taxonomic_rank_id 
        and tne.parent_id = 22102505 and cn.taxon_id = tne.taxon_id and cn.common_name_element_id = cne.id
        order by s.name_element;
    

Finne hvor mange arter som er i COL:

    select count(*) from taxon t, taxonomic_rank tr
    where tr.id = t.taxonomic_rank_id and tr.rank = 'species';


# Rails app
Lager en Ruby on Rails app for å bygge Biocaching artsdatabase.

    $ vagrant ssh
    $ cd /vagrant/
    $ mkdir rails
    $ cd rails
    $ rails new speciesdb -d mysql
    $ cd speciesdb


Databasebruker for rails (speciesdb) skal ha blitt opprettet i MariaDB.

Installerer gems: 

    $ bundle install

Kjører kommando for å opprette databaser: 

    $ rake db:create

Kjører migreringer: 

    $ rake db:migrate

Importere data fra COL (alle kingdoms og så chordata (ryggstrengdyr)): 

    $ rake col:import_top_levels
    $ rake col:import[22032976]

Indeksere ett artsnavn i Elasticsearch:

    $ rake es:import_one

Indeksere alle artsnavn i Elasticsearch: 

    $ rake es:import

## Starte Rails

Kan starte rails slik: 

    $ cd /vagrant/rails/
    $ rails s -b 0.0.0.0

Og åpne railsapplikasjonen på denne adressen http://localhost:3000