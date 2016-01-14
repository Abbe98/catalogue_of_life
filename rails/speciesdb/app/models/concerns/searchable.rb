# https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-model
#
module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    
    index_name 'taxa'
=begin    
    # http://stackoverflow.com/questions/25392300/rails-4-elasticsearch-rails
    settings index: { 
      number_of_shards: 1,
      analysis: {
        filter: {
          trigrams_filter: {
            type: 'ngram',
            min_gram: 2,
            max_gram: 10
          },
          content_filter: {
            type: 'ngram',
            min_gram: 4,
            max_gram: 20
          }
        },
        analyzer: {
          index_trigrams_analyzer: {
            type: 'custom',
            tokenizer: 'standard',
            filter: ['lowercase', 'trigrams_filter']
          },
          search_trigrams_analyzer: {
            type: 'custom',
            tokenizer: 'whitespace',
            filter: ['lowercase']
          },
          english: {
            tokenizer: 'standard',
            filter: ['standard', 'lowercase', 'content_filter']
          }
        }
      } 
    }
=end    
    settings index: { 
      number_of_shards: 1,
      }     do
      mapping do
        indexes :species, type: 'multi_field' do
          indexes :tokenized, analyzer: 'simple'
        end
      end
      # mappings dynamic: 'false' do
      #   indexes :title, analyzer: 'english', index_options: 'offsets'
      # end
    end
    

    
    # Customize the JSON serialization for Elasticsearch
    # ref http://ericlondon.com/2014/09/02/rails-4-elasticsearch-integration-with-dynamic-facets-and-filters-via-model-concern.html
    #
    def as_indexed_json(options={})
      hash = self.as_json(only: [:binomial_name, :slug, :col_taxon_id, :id], 
                          methods: [:scientific_name],
                          include: { common_names:{only: [:name, :language_iso] }})
      #hash['species'] = self.species.map(&:title)
      hash
    end
    
    def self.search(query)
      options ||= {}

      # setup empty search definition
      @search_definition = {
        query: {},
        filter: {},
        highlight: {},
      }
      # query
      unless query.blank?
        @search_definition[:query] = {
          bool: {
            should: [
              { multi_match: {
                  query: query,
                  # limit which fields to search, or boost here:
                  fields: [ "scientific_name", "common_names.name" ],
                  operator: 'and'
                }
              }
            ]
          }
        }
      else
        @search_definition[:query] = { match_all: {} }
      end
      
      @search_definition[:highlight] = { 
        pre_tags: ["<span class=\"highlight\">"],
        post_tags: ["</span>"],
        fields: {"common_names.name"  => {}, scientific_name: {} } 
      }
      
      # execute Elasticsearch search
      __elasticsearch__.search(@search_definition)

    end

    private

    # return array of model attributes to search on
    def search_text_fields
      #self.content_columns.select {|c| [:string,:text].include?(c.type) }.map {|c| c.name }
      
    end
          
    
  end
  
end