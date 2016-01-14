class RankTaxon < ActiveRecord::Base
  self.table_name = "ranks_taxa"
  belongs_to :taxon
  belongs_to :rank
end
