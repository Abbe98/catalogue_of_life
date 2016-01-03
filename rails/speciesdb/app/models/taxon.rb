
class Taxon < ActiveRecord::Base
  
  has_many :children, class_name: "Taxon", foreign_key: "parent_id"

  belongs_to :parent, class_name: "Taxon"  
  
  has_many :common_names, -> { where nameable_type: 'Taxon', nameable_subtype: 'common_names'}, {class_name: 'Name', foreign_key: 'nameable_id', dependent: :destroy} do
    def << (value)
      value.nameable_type = 'Taxon'
      value.nameable_subtype = 'common_names'
      super value
    end

  end
  
  has_many :ranks, -> { where nameable_type: 'Taxon', nameable_subtype: 'ranks'}, {class_name: 'Name', foreign_key: 'nameable_id', dependent: :destroy} do
    def << (value)
      value.nameable_type = 'Taxon'
      value.nameable_subtype = 'ranks'
      super value
    end

  end  

    
end
