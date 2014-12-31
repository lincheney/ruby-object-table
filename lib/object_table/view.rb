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

  def set_column(name, value)
    col = get_column(name)
    unless col
      col = add_column(name)
      columns[name] = col
    end
    col[] = value
  end
  alias_method :[]=, :set_column

end
