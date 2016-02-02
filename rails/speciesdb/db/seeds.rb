# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
source = Source.create(slug: 'col', name: 'Catalogue of Life', version: COL_VERSION)
taxonomy = Taxonomy.create(slug: 'col', 
       product_name: 'Species 2000 & ITIS Catalogue of Life: 2013 Annual Checklist')
taxonomy.names << Name.new(name: "Catalogue of Life", language_iso: "eng", source: source)
