require_relative 'view_methods'
require_relative 'basic_grid'
require_relative 'masked_column'

class ObjectTable::View
  include ObjectTable::ViewMethods
  attr_reader :indices

  def initialize(parent, indices)
    super()
    @parent = parent
    @indices = indices
    columns
  end

  def columns
    @columns ||= super
  end

  def []=(name, value)
    col = (@parent.columns[name] or add_column(name))
    col[indices] = value
    columns[name] = ObjectTable::MaskedColumn.mask(col, indices)
  end

end
