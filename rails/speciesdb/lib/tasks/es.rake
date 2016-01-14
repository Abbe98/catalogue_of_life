require 'pp'

namespace :es do
  
  desc %{Index all species}
  task :index, [] => :environment do |t, args|
    Species.import force: true
  end
  
end
