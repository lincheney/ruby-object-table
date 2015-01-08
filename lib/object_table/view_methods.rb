require 'forwardable'
require_relative 'table_methods'

module ObjectTable::ViewMethods
  extend Forwardable
  include ObjectTable::TableMethods

  def columns
    ObjectTable::BasicGrid[@parent.columns.map{|k, v| [k, ObjectTable::MaskedColumn.mask(v, indices)]}]
  end

  def add_column(name, *args)
    col = @parent.add_column(name, *args)
    ObjectTable::MaskedColumn.mask(col, indices)
  end

  def pop_column(name)
    @parent.pop_column(name)
    super if @columns
  end

end