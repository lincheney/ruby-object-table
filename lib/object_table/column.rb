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

  def [](*)
    result = super
    result.is_a?(NArray) ? self.class.make(result) : result
  end

  def get_rows(rows, slice=false)
    if slice
      slice(*([nil] * (rank - 1)), rows)
    else
      self[*([nil] * (rank - 1)), rows]
    end
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
