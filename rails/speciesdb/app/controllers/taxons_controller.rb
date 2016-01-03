class TaxonsController < ApplicationController
  
  def index
    @taxa = Taxon.where('parent_id is null')
  end
  
end
