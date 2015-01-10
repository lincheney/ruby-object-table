require 'narray'

class ObjectTable::Column < NArray
  def self.make(value)
    value = case value
    when self
      value
    when NArray
      if value.rank <= 0
        self.new(value.typecode, 0)
      else
        cast(value)
      end
    when Range
      to_na(value.to_a)
    when Array
      to_na(value)
    else
      raise ArgumentError.new("Expected NArray or Array, got #{value.class}")
    end
    value
  end

  def slice(*)
    self.class.make super
  end

  def [](*a)
    result = super
    result.is_a?(NArray) ? self.class.make(result) : result
  end

  def []=(*args)
    if (args[-1].is_a?(Array) or args[-1].is_a?(NArray)) and args[-1].empty? and self.empty?
      return args[-1]
    end

    super
  end

  def to_object
    self.class.cast(self, 'object')
  end

  def uniq
    self.class.make to_a.uniq
  end

  def coerce_rev(other, operator)
    other.send(operator, NArray.refer(self))
  end

  def method_missing(*args)
    collect{|x| x.send(*args)}
  end

#   def collect(*)
#     self.class.make super, name
#   end

  def _refer(value)
    value.is_a?(NArray) ? NArray.refer(value) : value
  end

  %w{ + - * / }.each do |op|
    define_method(op) do |other|
      #self.class.make super(_refer(other)), name
      super(_refer(other))
    end
  end

  %w{ xor or and <= >= le ge < > gt lt % ** ne eq & | ^ to_type }.each do |op|
    define_method(op) do |other|
      self.class.make super(other)
    end
  end

#   %w{ not abs -@ ~ }.each do |op|
#     define_method(op) do
#       self.class.make super()
# #     end
#   end

end
