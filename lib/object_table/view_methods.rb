require 'forwardable'
require_relative 'table_methods'

module ObjectTable::ViewMethods
  extend Forwardable
  include ObjectTable::TableMethods

  def_delegators :@parent, :add_column

  def columns
    ObjectTable::BasicGrid[@parent.columns.map{|k, v| [k, ObjectTable::MaskedColumn.mask(v, indices)]}]
  end

end