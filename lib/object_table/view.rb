require_relative 'table_methods'

class ObjectTable::View
  include ObjectTable::TableMethods

  def initialize(parent, mask: nil, &block)
    super()
    @parent = parent
    @mask = mask
    @filter = block
  end

  def columns
    @columns ||= Hash[@parent.columns.map{|k, v| [k, v[mask]]}]
  end

  def []=(name, value)
    column = @parent.columns[name]
    unless column
      column = @parent.add_column(name)
    end
    column[mask] = value
  end

  def mask
    @mask ||= @parent.apply &@filter
  end

end