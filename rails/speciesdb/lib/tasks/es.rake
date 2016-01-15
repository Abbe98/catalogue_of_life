require 'pp'

namespace :es do
  
  desc %{Index all species}
  task :import, [] => :environment do |t, args|
    Species.import force: true
  end
  
  desc %{Index only one species}
  task :import_one, [] => :environment do |t, args|
    Species.import scope: :one, force: :true
  end

  desc %{Delete the species index}
  task :delete_all, [] => :environment do |t, args|
    Species.__elasticsearch__.create_index! force: true
  end

end
