require_relative "object_table/version"
require_relative "object_table/basic_grid"
require_relative "object_table/table_methods"
require_relative "object_table/view"
require_relative "object_table/temp_view"
require_relative "object_table/column"
require_relative "object_table/grouped"
require_relative "object_table/temp_grouped"

class ObjectTable
  include TableMethods

  attr_reader :columns

  def initialize(columns = {})
    super()

    unless columns.is_a? BasicGrid
      columns = BasicGrid[columns]
    end
    columns._ensure_uniform_columns!
    @columns = columns

    @columns.each do |k, v|
      @columns[k] = Column.make(v, k)
    end
  end

  def add_column(name, typecode='object', *args)
    col = ObjectTable::Column.new(typecode, *args, nrows)
    col.name = name
    columns[name] = col
  end

  def stack!(*others)
    new_values = Hash.new{ [] }

    others.each do |x|
      case x
      when ObjectTable::TableMethods
        x = x.columns
      when BasicGrid
        x._ensure_uniform_columns!
      end

      raise "Don't know how to append a #{x.class}" unless x.is_a?(BasicGrid)
      raise 'Mismatch in column names' unless (colnames | x.keys).length == colnames.length

      x.each do |k, v|
        v = v.to_a if v.is_a? NArray
        new_values[k] += v
      end
    end

    return self if new_values.empty?

    new_values.each do |k, v|
      @columns[k] = Column.make(@columns[k].to_a + v, k)
    end
    self
  end

  def self.stack(*values)
    return self.new if values.empty?
    base = values.shift

    case base
    when BasicGrid
      base = self.new(base.clone)
    when ObjectTable, ObjectTable::View
      base = base.clone
    else
      raise "Don't know how to join a #{base.class}"
    end
    base.stack!(*values)
  end

  def sort_by!(*keys)
    sort_index = _get_sort_index(keys)

    columns.each do |k, v|
      columns[k] = v[sort_index]
    end
    self
  end

end
