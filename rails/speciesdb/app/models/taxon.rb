
class Taxon < ActiveRecord::Base
  
  has_many :children, class_name: "Taxon", foreign_key: "parent_id"
  belongs_to :parent, class_name: "Taxon"  
  belongs_to :taxonomy
  
  belongs_to :source_database
  
  include Searchable
  
  has_many :common_names, as: :nameable, class_name: 'Name'
  # trenger ikke denne likevel, siden taxon har bare en assosiasjon til Name
  # has_many :common_names, -> { where nameable_type: 'Taxon', nameable_subtype: 'common_names'}, {class_name: 'Name', foreign_key: 'nameable_id', dependent: :destroy} do
  #   def << (value)
  #     value.nameable_type = 'Taxon'
  #     value.nameable_subtype = 'common_names'
  #     super value
  #   end
  #
  # end
  
  #has_and_belongs_to_many :ranks
  has_many :rank_taxon
  has_many :ranks, :through => :rank_taxon


  #scope :genus, -> { where rank.name = "genus" and rank.language_iso = "eng" }

  scope :genuses, -> { includes(:ranks).where(:ranks=>{rank: "genus", language_iso: "eng"})}
  scope :species, -> { includes(:ranks).where(:ranks=>{rank: "species", language_iso: "eng"})}
  scope :kingdoms, -> { includes(:ranks).where(:ranks=>{rank: "kingdom", language_iso: "eng"})}
  scope :infraspecific, -> { includes(:ranks).where(:ranks=>{rank: INFRASPECIFIC_RANKS, language_iso: "eng"})}
  scope :one, -> { where slug: 'soriculus-nigrescens' }

  
  #trenger ikke denne likevel:
  # has_many :ranks,  -> { where nameable_type: 'Taxon', nameable_subtype: 'ranks'}, {class_name: 'Name', foreign_key: 'nameable_id', dependent: :destroy} do
  #   def << (value)
  #     value.nameable_type = 'Taxon'
  #     value.nameable_subtype = 'ranks'
  #     super value
  #   end
  # end
  
  # has_many :ranks, -> { where nameable_type: 'Taxon', nameable_subtype: 'ranks'}, {class_name: 'Name', foreign_key: 'nameable_id', dependent: :destroy} do
  #   def << (value)
  #     value.nameable_type = 'Taxon'
  #     value.nameable_subtype = 'ranks'
  #     super value
  #   end
  #
  # end 

  def scientific_name
    taxon_scientific_name
  end
  
  def common_name(language_iso)
    names = common_names.select{|name| name.language_iso == language_iso}
    names.empty? ? "" : names.first.name
  end
  
  def taxonomic_ranks
    this = {"#{ranks.select{|name| name.language_iso == 'eng'}.first.rank}" => taxon_scientific_name}
    parent.present? ? this.merge(parent.taxonomic_ranks) : this
  end
  
  def genus_scientific_name
    rank = ranks.select{|name| name.language_iso == 'eng'}.first
    rank.rank == "genus" ? taxon_scientific_name : (parent_id.present? ? parent.genus_scientific_name : "UNKNOWN GENUS")   
  end
  
  def kingdom
    rank = ranks.select{|name| name.language_iso == 'eng'}.first
    if rank.rank == "kingdom"
      return taxon_scientific_name
    elsif parent.present?
      return parent.kingdom
    end
  end
  
  def source
    {taxonomy: taxonomy.product_name, source_database: source_database.as_json(except: [:updated_at, :created_at])}
  end
  
end
