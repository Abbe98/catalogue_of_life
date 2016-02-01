class TaxonomiesController < ApplicationController
  
  def index
    @query = request.post? ? Query.new(params[:query]) : Query.new         
    @taxonomies = Taxonomy.all.order(:product_name)
    respond_to do |format|
      format.html {
      }
      format.json { 
        render json: JSON.pretty_generate(@taxonomies.includes(:names).as_json)      
      }    
    end
  end
  
  def show
  end
  
end
