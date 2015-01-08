require_relative 'column'

class ObjectTable::MaskedColumn < ObjectTable::Column
  attr_accessor :indices, :parent, :padded_dims

  def self.mask(parent, indices)
    padded_dims = [nil] * (parent.rank - 1)
    masked = parent.slice(*padded_dims, indices)

    if masked.rank <= 0
      column = self.new(masked.typecode, 0)
    else
      column = self.new(masked.typecode, *masked.shape)
      column.super_slice_assign(masked)
    end

    column.parent = parent
    column.indices = indices
    column.padded_dims = padded_dims
    column
  end

# let ObjectTable::Column do this, since we've overriden []=
  def self.make(*args)
    ObjectTable::Column.make(*args)
  end

  alias_method :super_slice_assign, :[]=

  def []=(*keys, value)
    parent[*padded_dims, indices[*keys]] = value
    super
  end

#   make destructive methods affect parent
  %w{ fill! indgen! indgen random! map! collect! conj! imag= mod! add! div! sbt! mul! }.each do |op|
    define_method(op) do |*args, &block|
      result = super(*args, &block)
      parent[*padded_dims, indices] = result
      result
    end
  end

  %w{ + - / * % ** to_type not abs -@ ~ }.each do |op|
    define_method(op) do |*args|
      ObjectTable::Column.cast super(*args)
    end
  end

  def clone
    ObjectTable::Column.cast(self).clone
  end

end
