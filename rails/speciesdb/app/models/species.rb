class Species < Taxon
  validates :slug, uniqueness: true, allow_nil: true
  
  include Searchable
  
  scope :one, -> { where slug: 'soriculus-nigrescens' }
  
  def scientific_name
    binomial_name
  end
  
  def binomial_name
    #"#{parent.genus_scientific_name} #{scientific_name}"

    "#{parent.genus_scientific_name} #{taxon_scientific_name}"
    # parent = self.parent
    # rank = parent.ranks.select{|name| name.language_iso == 'eng'}.first
    # pp parent
    # pp parent.ranks
    # if rank.rank == "genus"
    #   "#{parent.scientific_name} #{scientific_name}"
    # else
    #   "#{rank.rank} #{scientific_name}"
    # end
  end

  
end
