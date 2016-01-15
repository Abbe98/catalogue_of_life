class TaxaController < ApplicationController

  respond_to :json, :html
    
  def index
    @taxa = Taxon.includes(:common_names, :ranks).where('parent_id is null')
  end
  
  def search
    respond_to do |format|
      format.html {
        @query = request.post? ? Query.new(params[:query]) : Query.new         
      }
      format.json { 
        es_result = Species.search params[:term]        
        render json: es_result
      }    
    end
  end
  
  def show
    pp params

    @taxon = Taxon.includes(:common_names, :ranks).find(params[:id])   
    pp @taxon
    respond_to do |format|
      format.html
      format.json { 
        render json: @taxon.to_json
      }    
    end
  end
  
  def subtree
    @taxon = Taxon.includes(:common_names, :ranks).find(params[:id])
  end
  
end
