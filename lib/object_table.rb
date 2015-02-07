require_relative "object_table/version"
require_relative "object_table/basic_grid"
require_relative "object_table/table_methods"
require_relative "object_table/view"
require_relative "object_table/static_view"
require_relative "object_table/column"
require_relative "object_table/grouped"

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
      @columns[k] = ObjectTable::Column.make(v)
    end
  end

  def add_column(name, typecode='object', *args)
    col = ObjectTable::Column.new(typecode, *args, nrows)
    columns[name] = col
  end

  def stack!(*others)
    new_values = Hash[colnames.zip(ncols.times.map{[]})]

    others.each do |x|
      case x
      when ObjectTable::TableMethods
        x = x.columns
      when ObjectTable::BasicGrid
        x._ensure_uniform_columns!
      end

      raise "Don't know how to append a #{x.class}" unless x.is_a?(ObjectTable::BasicGrid)
      next if x.empty?
      raise 'Mismatch in column names' unless (colnames - x.keys).empty?

      x.each do |k, v|
        new_values[k].push NArray.to_na(v)
      end
    end

    return self if new_values.empty?
    new_rows = new_values.values.first.map{|x| x.shape[-1]}.reduce(:+)
    return self unless (new_rows and new_rows != 0)

    new_values.each do |k, v|
      @columns[k] = @columns[k].stack(*v)
    end
    self
  end

  def self.stack(*values)
    return self.new if values.empty?
    base = values.shift

    case base
    when ObjectTable::BasicGrid
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


  def __static_view_cls__
    self.class::StaticView
  end

  def __view_cls__
    self.class::View
  end

  def __group_cls__
    self.class::Group
  end

  def __table_cls__
    self.class
  end

end
