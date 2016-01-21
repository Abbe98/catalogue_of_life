
require 'json'
class TaxaController < ApplicationController

  respond_to :json, :html, :js
    
  def index
    respond_to do |format|
      format.html {
        @taxa = Taxon.includes(:common_names, :ranks).where('parent_id is null')      
      }
      format.json { 
        options = { from: params[:from], 
                    size: params[:size],
                    rank: params[:rank],
                    kingdom: params[:kingdom],
                    below_rank: params[:below_rank],
                    below_rank_value: params[:below_rank_value]}
        response = Taxon.search(params[:term], options)        
        result = { total: response.results.total, 
                   max_score: response.results.max_score, 
                   number_of_hits: response.records.size,
                   hits: response}
        render json: JSON.pretty_generate(result.as_json)
        #render json: JSON.pretty_generate(response.as_json)
        #render json: response.to_json
      }    
    end
    
  end
  
  def search
    respond_to do |format|
      format.html {
        @query = request.post? ? Query.new(params[:query]) : Query.new         
      }
=begin      
      format.json { 
        options = { from: params[:from], 
                    size: params[:size],
                    rank: params[:rank],
                    kingdom: params[:kingdom],
                    below_rank: params[:below_rank],
                    below_rank_value: params[:below_rank_value]}
        response = Taxon.search(params[:term], options)        
        result = { total: response.results.total, 
                   max_score: response.results.max_score, 
                   number_of_hits: response.records.size,
                   hits: response}
        render json: JSON.pretty_generate(result.as_json)
        #render json: JSON.pretty_generate(response.as_json)
        #render json: response.to_json
      }    
=end      
    end
  end
  
  def show
    pp params

    @taxon = Taxon.includes(:common_names, :ranks).find(params[:id])   
    pp @taxon
    respond_to do |format|
      format.html
      format.js
      format.json { 
        render json: JSON.pretty_generate(@taxon.as_json(include: :common_names))
      }    
    end
  end
  
  def subtree
    @taxon = Taxon.includes(:common_names, :ranks).find(params[:id])
  end
  
end
