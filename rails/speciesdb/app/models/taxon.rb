
class Taxon < ActiveRecord::Base
  
  has_many :children, class_name: "Taxon", foreign_key: "parent_id"
  belongs_to :parent, class_name: "Taxon"  
  
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

  def common_name(language_iso)
    common_names.select{|name| name.language_iso == language_iso}.first.name
  end
  
  def genus_scientific_name
    rank = ranks.select{|name| name.language_iso == 'eng'}.first
    rank.rank == "genus" ? taxon_scientific_name : (parent_id.present? ? parent.genus_scientific_name : "UNKNOWN GENUS")   
  end
      
end
