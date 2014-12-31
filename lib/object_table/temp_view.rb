require 'forwardable'
require_relative 'view_methods'
require_relative 'masked_column'
require_relative 'view'

class ObjectTable::TempView
  include ObjectTable::ViewMethods

  extend Forwardable
  def_delegators :make_view, :group, :apply

  def initialize(parent, &block)
    super()
    @parent = parent
    @filter = block
  end

  def_delegators :@parent, :has_column?

  def get_column(name)
    col = @parent.get_column(name)
    ObjectTable::MaskedColumn.mask(col, indices) if col
  end
  alias_method :[], :get_column

  def set_column(name, value)
    col = (@parent.get_column(name) or add_column(name))
    mask = indices
    col[mask] = value
#     ObjectTable::MaskedColumn.mask(col, mask)
  end
  alias_method :[]=, :set_column

  def indices
    NArray.int(@parent.nrows).indgen![@parent.apply &@filter]
  end

  def make_view
    ObjectTable::View.new @parent, indices
  end

  def clone
    cols = ObjectTable::BasicGrid[@parent.columns.map{|k, v| [k, v[indices]]}]
    ObjectTable.new(cols)
  end

end
