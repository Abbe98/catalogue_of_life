class Rank < ActiveRecord::Base
  #has_and_belongs_to_many :taxons
  has_many :rank_taxon
  has_many :taxons, :through => :rank_taxon
end
