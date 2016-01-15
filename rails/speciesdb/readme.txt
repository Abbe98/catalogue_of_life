Lager modeller og ressurser:

    $ rails g model NamedObject name:string language_iso:string
    $ rails g model CommonName --parent=NamedObject
    $ rails g model Name --parent=NamedObject
    $ rails g model Rank --parent=NamedObject
    $ rails g resource Taxon scientific_name:string col_taxon_id:integer
    $ rails g model Species --parent=Taxon
    $ rails g resource Taxonomy