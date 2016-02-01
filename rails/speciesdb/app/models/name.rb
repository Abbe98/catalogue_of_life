class Name < ActiveRecord::Base
  belongs_to :nameable, polymorphic: true
  belongs_to :source
end
