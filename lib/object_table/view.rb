require_relative 'table_methods'

class ObjectTable::View
  include ObjectTable::TableMethods

  def initialize(parent, &block)
    @parent = parent
    @filter = block
  end

  def columns
    @columns ||= Hash[@parent.columns.map{|k, v| [k, v[mask]]}]
  end

  def mask
    @mask ||= @parent.apply &@filter
  end

end