require 'pp'

class AutocompleteController < ApplicationController

  respond_to :json
  
  def new
    pp params
    puts "new----"
    #query = Species.order(:navn).where("picture_url is not null and navn ILIKE ?", "%#{params[:term]}%")
    #query = Species.order(:navn).where("navn ILIKE ?", "%#{params[:term]}%")
    query = Taxon.joins(:common_names).where("names.name like ?", "%#{params[:term]}%")
    # if params[:pictures].present? and params[:pictures] == "1"
    #   query = query.where("picture_url is not null")
    # end
    species = query.limit(10)
    respond_to do |format|
      format.html
      format.json { 
        puts "------------"
        #map = species.map{|s| [s.navn,s.picture_url] }
        map = species.map{|s| [s.common_name('eng'), s.id] }
        #map = species.map(&:navn)
        pp map
        
        render json: map
      }
    end
  end
  
  def es_new
    pp params
    puts "new ES search"

    es_result = Taxon.search params[:term]
    es_result.results.each do |res|
      puts res.highlight.inspect
      puts res.highlight.scientific_name if res.highlight.scientific_name.present?
      puts res.highlight["common_names.name"] if res.highlight["common_names.name"].present?
    end
    respond_to do |format|
      format.html
      format.json { 
        puts "------------"
        #map = species.map{|s| [s.navn,s.picture_url] }
        puts es_result.size
        map = es_result.results.map do |s| 
          hl = s.highlight
          src = s._source
          scientific_name = hl.scientific_name.present? ? hl.scientific_name : src.scientific_name
          rank = src.ranks.select{|rank| rank.language_iso == 'eng'}.first.rank
          pp src
          common_name = (src.common_names.nil? or src.common_names.empty?) ? rank : src.common_names.first.name
          hl_common_name = hl["common_names.name"].present? ? hl["common_names.name"] : common_name
          [common_name, hl_common_name, scientific_name, src.id] 
        end
        #map = species.map(&:navn)
        pp map
        
        render json: map
      }
    end
  end

  
end
