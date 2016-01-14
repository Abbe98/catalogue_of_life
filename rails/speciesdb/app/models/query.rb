class Query

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_accessor :q, :with_pictures_only
  
  def initialize(params = {})  
    @q = params[:q]
    @with_pictures_only = params[:with_pictures_only]
  end
  
  def persisted?
    false
  end  
     
  def q_str
    tmp = @q.blank? ? "%" : @q
    tmp
    #"%2B#{tmp}+_val_:\"popularity\""
  end

end
