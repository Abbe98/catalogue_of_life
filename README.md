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
    
    MariaDB [col2015ac]> 
