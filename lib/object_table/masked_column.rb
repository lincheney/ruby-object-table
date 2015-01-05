require_relative 'column'

class ObjectTable::MaskedColumn < ObjectTable::Column
  attr_accessor :indices, :parent

  def self.mask(parent, indices)
    masked = parent[indices]
    column = self.new(masked.typecode, *masked.shape)
    column.super_slice_assign(masked)
    column.parent = parent
    column.indices = indices
    column.name = parent.name
    column
  end

# let ObjectTable::Column do this, since we've overriden []=
  def self.make(*args)
    ObjectTable::Column.make(*args)
  end

  alias_method :super_slice_assign, :[]=

  def []=(*keys, value)
    parent[indices[*keys]] = value
    super
  end

  %w{ fill! indgen! indgen random! map! collect! conj! imag= mod! add! div! sbt! mul! }.each do |op|
    define_method(op) do |*args, &block|
      result = super(*args, &block)
      parent[indices] = result
      result
    end
  end

  %w{ + - / * % ** to_type not abs -@ ~ }.each do |op|
    define_method(op) do |*args|
      ObjectTable::Column.cast super(*args)
    end
  end

  def clone
    col = ObjectTable::Column.cast(self).clone
    col.name = name
    col
  end

end
