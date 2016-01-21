#!/bin/sh
curl -XDELETE http://localhost:9200/taxa
curl -XPUT 'http://localhost:9200/taxa/' -d '{
    "settings" : {
        "number_of_shards" : 1,
        "analysis" : {
            "analyzer": {
                "my_ngram_analyzer": {
                    "tokenizer": "my_ngram_tokenizer",
                    "filter": ["lowercase"]
                }
            },
            "tokenizer": {
                "my_ngram_tokenizer": {
                    "type": "nGram",
                    "min_gram": 2,
                    "max_gram": 20,
                    "token_chars": ["letter", "digit"]
                }
            }
        }
    },
    "mappings" : {
        "taxon" : {
            "_source" : { "enabled" : true },
            "properties" : {
                "scientific_name" : { 
                  "type" : "string", 
                  "analyzer" : "my_ngram_analyzer", 
                  "search_analyzer" : "simple"
                }, 
                "slug": { "type": "string", "index": "not_analyzed" },      
                "id": { "type": "string", "index": "not_analyzed" },      
                "kingdom": { "type": "string", "index": "not_analyzed" }, 
                "col_taxon_id": { "type": "string", "index": "not_analyzed" },     
                "taxonomy": {
                  "properties": {
                      "slug": { "type": "string", "index": "not_analyzed" }
                  }
                },
                "common_names": {
                    "properties": {
                      "name": { "type": "string", 
                                "analyzer" : "my_ngram_analyzer", 
                                "search_analyzer" : "simple" 
                            }, 
                      "language_iso": { "type": "string", "index": "not_analyzed" }
                    }
                },    
                "ranks": {
                    "properties": {
                      "rank": { "type": "string", "index": "not_analyzed" }, 
                      "language_iso": { "type": "string", "index": "not_analyzed" }
                    }
                }               
            },
            "dynamic_templates": [
                { 
                  "notanalyzed": {
                      "path_match":         "taxonomic_ranks.*", 
                      "match_mapping_type": "string",
                      "mapping": {
                          "type":        "string",
                          "index":       "not_analyzed"
                      }
                   }
                }
                ]
        }
    }    
    
}'