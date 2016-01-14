class TaxaController < ApplicationController
  
  def index
    @taxa = Taxon.includes(:common_names, :ranks).where('parent_id is null')
  end
  
  def search
    @query = request.post? ? Query.new(params[:query]) : Query.new 
  end
  
  def show
    pp params
    @taxon = Taxon.includes(:common_names, :ranks).find(params[:id])
    pp @taxon
  end
  
  def subtree
    @taxon = Taxon.includes(:common_names, :ranks).find(params[:id])
  end
  
end
