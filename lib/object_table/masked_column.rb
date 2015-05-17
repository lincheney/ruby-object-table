require_relative 'column'

class ObjectTable::MaskedColumn < NArray
  attr_accessor :indices, :parent

  EMPTY = NArray[]

  def self.mask(parent, indices)
    if parent.empty?
      masked = parent.slice(indices)
    else
      masked = parent.slice(false, indices)
    end

    if masked.rank <= 0
      column = new(masked.typecode, 0)
    else
      column = cast(masked)
    end

    column.parent = parent
    column.indices = indices
    column
  end

  def []=(*keys, value)
    unless parent.nil? or ((value.is_a?(Array) or value.is_a?(NArray)) and value.empty?)
      parent[false, indices[*keys]] = value
    end
    super
  end

#   make destructive methods affect parent
  %w{ fill! indgen! indgen random! map! collect! conj! imag= mod! add! div! sbt! mul! }.each do |op|
    define_method(op) do |*args, &block|
      result = super(*args, &block)
      parent[false, indices] = result if parent
      result
    end
  end

  def clone
    return NArray.new(typecode, 0) if empty?
    NArray.cast(self).clone
  end

  def coerce_rev(other, operator)
    return other.send(operator, EMPTY) if empty?
    other.send(operator, NArray.cast(self))
  end

end
