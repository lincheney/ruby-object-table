require 'narray'

class ObjectTable::Column < NArray
  attr_accessor :name

  def self.make(value, name = nil)
    value = case value
    when self
      value
    when NArray
      to_na(value.to_a)
    when Array
      to_na(value)
    else
      raise ArgumentError.new("Expected NArray or Array, got #{value.class}")
    end
    value.name = name
    value
  end

end
