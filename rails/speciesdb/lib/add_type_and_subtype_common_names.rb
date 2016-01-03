module AddTypeAndSubtypeCommonNames

  def << *args
    arg = args.first
    puts arg.class.name
    if arg.is_a?(Name)
      arg.nameable_type = 'Taxon'
      arg.nameable_subtype = 'common_names'
      self.push([arg]) 
      return self
    else
      raise "Invalid Value"
    end
  end
  
end
