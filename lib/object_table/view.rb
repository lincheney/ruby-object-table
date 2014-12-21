require_relative 'table_methods'
require_relative 'basic_grid'
require_relative 'masked_column'

class ObjectTable::View
  include ObjectTable::TableMethods

  def initialize(parent, mask: nil, &block)
    super()
    @parent = parent
    @indices = NArray.int(parent.nrows).indgen![mask] if mask
    @filter = block
  end

  def columns
    @columns ||= ObjectTable::BasicGrid[@parent.columns.map{|k, v| [k, ObjectTable::MaskedColumn.mask(v, indices)]}]
  end

  def []=(name, value)
    col = @parent.columns[name]
    unless col
      col = @parent.add_column(name)
    end
    col[indices] = value
    columns[name] = ObjectTable::MaskedColumn.mask(col, indices)
  end

  def indices
    @indices ||= NArray.int(@parent.nrows).indgen![@parent.apply &@filter]
  end

end