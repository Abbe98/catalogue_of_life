require 'pp'

namespace :es do

  desc %{Index all taxa}
  task :import_all, [] => :environment do |t, args|
    Taxon.import
  end  
  
  desc %{Index all species}
  task :import_species_levels, [] => :environment do |t, args|
    #Taxon.import scope: :genuses
    Taxon.import scope: :species
    Taxon.import scope: :infraspecific
  end
  
  desc %{Index only one species}
  task :import_one, [] => :environment do |t, args|
    Taxon.import scope: :one
  end
  
  desc %{Index the kingdoms}
  task :import_kingdoms, [] => :environment do |t, args|
    Taxon.import scope: :kingdoms
  end
  
  desc %{Index the genuses}
  task :import_genuses, [] => :environment do |t, args|
    Taxon.import scope: :genuses
  end
  
  desc %{Index the species}
  task :import_species, [] => :environment do |t, args|
    Taxon.import scope: :species
  end
  
  desc %{Delete the species index}
  task :delete_all, [] => :environment do |t, args|
    Taxon.__elasticsearch__.create_index! force: true
  end

end
