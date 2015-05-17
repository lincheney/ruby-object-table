require 'forwardable'

require_relative 'table_methods'
require_relative 'factory'

module ObjectTable::ViewMethods
  extend Forwardable
  include ObjectTable::TableMethods
  include ObjectTable::Factory::SubFactory

  def_delegators :@parent, :has_column?

  def nrows
    indices.length
  end

  def columns
    ObjectTable::BasicGrid[@parent.columns.map{|k, v| [k, ObjectTable::MaskedColumn.mask(v, indices)]}]
  end

  def get_column(name)
    col = @parent.get_column(name)
    ObjectTable::MaskedColumn.mask(col, indices) if col
  end
  alias_method :[], :get_column

  def add_column(name, *args)
    col = @parent.add_column(name, *args)
    ObjectTable::MaskedColumn.mask(col, indices)
  end

  def pop_column(name)
    @parent.pop_column(name)
    super if @columns
  end

end