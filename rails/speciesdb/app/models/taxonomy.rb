class Taxonomy < ActiveRecord::Base
  has_many :names, as: :nameable
  has_many :taxa
end
