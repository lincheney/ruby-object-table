require 'narray'

class ObjectTable::Column < NArray
  attr_accessor :name

  def self.make(value, name = nil)
    value = case value
    when self
      value
    when NArray
      cast(value)
    when Range
      to_na(value.to_a)
    when Array
      to_na(value)
    else
      raise ArgumentError.new("Expected NArray or Array, got #{value.class}")
    end
    value.name = name
    value
  end

  def uniq
    self.class.make to_a.uniq, name
  end

  def coerce_rev(other, operator)
    other.send(operator, NArray.refer(self))
  end

  def method_missing(*args)
    map{|x| x.send(*args)}
  end

  def collect(*)
    self.class.make super, name
  end

  def _refer(value)
    value.is_a?(NArray) ? NArray.refer(value) : value
  end

  %w{ + - * / }.each do |op|
    define_method(op) do |other|
      self.class.make super(_refer(other)), name
    end
  end

  %w{ xor or and <= >= le ge < > gt lt % ** ne eq & | ^ }.each do |op|
    define_method(op) do |other|
      self.class.make super(other), name
    end
  end

  %w{ not abs -@ ~ }.each do |op|
    define_method(op) do
      self.class.make super(), name
    end
  end

end
