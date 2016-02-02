# https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-model
#
module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    
    # Oppretter heller indeksen vha script/recreate_es_index.sh
    
    # index_name 'taxa'
    #
    # # http://stackoverflow.com/questions/25392300/rails-4-elasticsearch-rails
    # settings index: {
    #   number_of_shards: 1,
    #   analysis: {
    #     analyzer: {
    #       my_ngram_analyzer: {
    #         tokenizer: "my_ngram_tokenizer",
    #         filter: ['lowercase']
    #       }
    #     },
    #     tokenizer: {
    #       my_ngram_tokenizer: {
    #         type: "nGram",
    #         min_gram: "2",
    #         max_gram: "20",
    #         token_chars: [:letter, :digit]
    #       }
    #     }
    #     }
    #     } do
    #       # mappings dynamic: 'false' do
    #       #  indexes :scientific_name, analyzer: 'my_ngram_analyzer', search_analyzer: 'simple'
    #       #  indexes "common_names.name", analyzer: 'my_ngram_analyzer', search_analyzer: 'simple'
    #       # end
    #       mappings do
    #         indexes :scientific_name, analyzer: 'my_ngram_analyzer', search_analyzer: 'simple'
    #         indexes :common_names do
    #           indexes :name, analyzer: 'my_ngram_analyzer', search_analyzer: 'simple'
    #         end
    #         indexes :slug, index: :not_analyzed
    #         indexes :kingdom, index: :not_analyzed
    #         indexes :id, index: :not_analyzed
    #         indexes :col_taxon_id, index: :not_analyzed
    #         indexes :taxonomy do
    #           indexes :slug, index: :not_analyzed
    #         end
    #         indexes :ranks do
    #           indexes :rank, index: :not_analyzed
    #           indexes :language_iso, index: :not_analyzed
    #         end
    #         # dynamic_templates do
    #         # end
    #       end
    #     end
        
        # filter: {
        #   trigrams_filter: {
        #     type: 'ngram',
        #     min_gram: 2,
        #     max_gram: 10
        #   },
        #   content_filter: {
        #     type: 'ngram',
        #     min_gram: 4,
        #     max_gram: 20
        #   }
        # },
        # analyzer: {
        #   index_trigrams_analyzer: {
        #     type: 'custom',
        #     tokenizer: 'standard',
        #     filter: ['lowercase', 'trigrams_filter']
        #   },
        #   search_trigrams_analyzer: {
        #     type: 'custom',
        #     tokenizer: 'whitespace',
        #     filter: ['lowercase']
        #   },
        #   english: {
        #     tokenizer: 'standard',
        #     filter: ['standard', 'lowercase', 'content_filter']
        #   }
        # }

    #
    # settings index: {
    #   number_of_shards: 1,
    #   }     do
    #   mapping do
    #     indexes :species, type: 'multi_field' do
    #       indexes :tokenized, analyzer: 'simple'
    #     end
    #   end
    #   # mappings dynamic: 'false' do
    #   #   indexes :title, analyzer: 'english', index_options: 'offsets'
    #   # end
    # end
    

    
    # Customize the JSON serialization for Elasticsearch
    # ref http://ericlondon.com/2014/09/02/rails-4-elasticsearch-integration-with-dynamic-facets-and-filters-via-model-concern.html
    #
    def as_indexed_json(options={})
      hash = self.as_json(only: [:taxon_scientific_name, :slug, :col_taxon_id, :id, :parent_id], 
                          methods: [:scientific_name, :kingdom, :taxonomic_ranks, :source],
                          include: { common_names:{only: [:name, :language_iso]},
                                     ranks:       {only: [:rank, :language_iso]},
                                     taxonomy: {only: :slug}})
      #hash['species'] = self.species.map(&:title)
      hash
    end
    
    def self.build_rank_filter(ranks, language_iso)
      array = []
      for r in ranks do
        array << { bool: { must: [{ term: {"ranks.rank" => r}}, {term: {"ranks.language_iso" => language_iso}}]}}
      end
      array
    end

    def self.build_language_filter(languages)
      array = []
      for l in languages do
        array << { term: {"common_names.language_iso" => l}}
      end
      {bool: {should: array}}
    end    
    
    
    def self.search(query, options={})
      #options ||= {}
      pp options[:languages]
      term_filter = {}
      filters = []
      if options[:below_rank].present? && options[:below_rank_value].present?
        filters << {term: {"taxonomic_ranks.#{options[:below_rank]}" => options[:below_rank_value]}}
      end
      # if options[:rank].present?
      #   filters << {term: {"ranks.rank" => options[:rank]}}
      # end
      if options[:kingdom].present?
        filters << {term: {"kingdom" => options[:kingdom]}}
      end
      if options[:taxonomy_slug].present?
        filters << {term: {"taxonomy.slug" => options[:taxonomy_slug]}}
      end
      bool_filters = { should: build_rank_filter(RANKS_FOR_SEARCH, "eng")}
#      filters << {bool: { should: build_rank_filter(RANKS_FOR_SEARCH, "eng")}}
      
      if options[:languages].present? && !options[:languages].empty?
        bool_filters.merge!({ must: build_language_filter(options[:languages])})
      end

      filters << {bool: bool_filters}
      
      pp filters
      
      
      #filter for å kun søke i bestemte nivå:
=begin      
      "bool" : {
                "should" : [
                      {
                        "bool" : {
                          "must" : [
                              {"term" : {"ranks.rank" : "phylum"}},
                              {"term" : {"ranks.language_iso" : "eng"}}
                            ]
                        }
                      }, 
                      {
                        "bool" : {
                          "must" : [
                              {"term" : {"ranks.rank" : "kingdom"}},
                              {"term" : {"ranks.language_iso" : "eng"}}
                            ]
                        }
                      }
                  ]
              }
=end      
      pp filters
      
      
      # "bool" : {
      #   "should" : [
      #      { "term" : {"price" : 20}},
      #      { "term" : {"productID" : "XHDK-A-1293-#fJ3"}}
      #   ],
      #
      
      
      
      puts "options:"
      pp options
      
      filter = filters.empty? ? {} : { bool: { must: filters}}

      puts "filter:"
      pp filter
            
      # setup empty search definition
      @search_definition = {
        from: options[:from],
        size: options[:size],
        query: {},
        #sort: [{"common_names.name" => {order: :asc}}],
        filter: filter,
        highlight: {},       
        "_source" => ["id", "col_taxon_id", "scientific_name", "parent_id", "source", "ranks", "common_names"],
      }
      
      if options[:fields].present? && options[:fields] == "all"
        @search_definition["_source"] = "*"
      end
      
      # query
      unless query.blank?
        @search_definition[:query] = {
          bool: {
            must: [
              { multi_match: {
                  query: query,
                  # limit which fields to search, or boost here:
                  fields: [ "scientific_name", "common_names.name" ],
                  operator: :and
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
    
    
    def self.lookup(query, options={})
      #options ||= {}
      
      term_filter = {}
      filters = []
      if options[:below_rank].present? && options[:below_rank_value].present?
        filters << {term: {"taxonomic_ranks.#{options[:below_rank]}" => options[:below_rank_value]}}
      end
      if options[:rank].present?
        filters << {term: {"ranks.rank" => options[:rank]}}
      end
      if options[:kingdom].present?
        filters << {term: {"kingdom" => options[:kingdom]}}
      end
      if options[:parent_id].blank?
        filters << {missing: {"field" => "parent_id"}}
      else
        filters << {term: {"parent_id" => options[:parent_id]}}
        
      end
      pp filters
      
      
      # "bool" : {
      #   "should" : [
      #      { "term" : {"price" : 20}},
      #      { "term" : {"productID" : "XHDK-A-1293-#fJ3"}}
      #   ],
      #
      
      
      
      puts "options:"
      pp options
      
      filter = { bool: { must: filters}}

      puts "filter:"
      pp filter
            
      # setup empty search definition
      @search_definition = {
        from: options[:from],
        size: options[:size],
        query: {match_all: {}},
        #sort: [{"common_names.name" => {order: :asc}}],
        filter: filter,
        "_source" => ["id", "col_taxon_id", "scientific_name", "parent_id", "source", "ranks", "common_names"],
        highlight: {},
      }
      
      if options[:fields].present? && options[:fields] == "all"
        @search_definition["_source"] = "*"
      end
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