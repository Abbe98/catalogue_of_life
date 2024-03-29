class Species < Taxon
  validates :slug, uniqueness: true, allow_nil: true

  #include Elasticsearch::Model
  include Searchable
  include Elasticsearch::Model::Callbacks
  #document_type "species"

    
  def scientific_name
    name = "#{parent.genus_scientific_name} #{taxon_scientific_name}"
    name
  end
  
  #
  # def binomial_name
  #   #"#{parent.genus_scientific_name} #{scientific_name}"
  #
  #   name = "#{parent.genus_scientific_name} #{taxon_scientific_name}"
  #   puts name
  #   name
  #
  #   # parent = self.parent
  #   # rank = parent.ranks.select{|name| name.language_iso == 'eng'}.first
  #   # pp parent
  #   # pp parent.ranks
  #   # if rank.rank == "genus"
  #   #   "#{parent.scientific_name} #{scientific_name}"
  #   # else
  #   #   "#{rank.rank} #{scientific_name}"
  #   # end
  # end

  
end
