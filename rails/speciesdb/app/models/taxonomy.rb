class Taxonomy < ActiveRecord::Base
  has_many :names, as: :nameable
end
