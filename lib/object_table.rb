require_relative "object_table/version"
require_relative "object_table/basic_grid"
require_relative "object_table/table_methods"
require_relative "object_table/view"
require_relative "object_table/static_view"
require_relative "object_table/column"
require_relative "object_table/grouped"
require_relative "object_table/stacker"
require_relative "object_table/factory"

class ObjectTable
  include TableMethods
  include Stacker
  include Factory

  attr_reader :columns

  def initialize(columns = {})
    super()

    unless columns.is_a? BasicGrid
      columns = BasicGrid[columns]
    end
    columns._ensure_uniform_columns!
    @columns = columns

    @columns.each do |k, v|
      @columns[k] = NArray.to_na(v)
    end
  end

  def add_column(name, typecode='object', *args)
    col = NArray.new(typecode, *args, nrows)
    columns[name] = col
  end

  def sort_by!(*keys)
    sort_index = _get_sort_index(keys)

    columns.each do |k, v|
      columns[k] = v[sort_index]
    end
    self
  end

end
