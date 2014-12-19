require_relative "object_table/version"
require_relative "object_table/basic_grid"
require_relative "object_table/table_methods"
require_relative "object_table/view"
require_relative "object_table/column"
require_relative "object_table/grouped"

class ObjectTable
  include TableMethods

  attr_reader :columns

  def initialize(columns = {})
    @columns = BasicGrid[columns]
    @columns.ensure_uniform_columns!

    @columns.each do |k, v|
      @columns[k] = Column.make(v, k)
    end

    __setup__
  end

  def append!(*others)
    new_values = Hash.new{ [] }

    others.each do |x|
      if x.is_a?(ObjectTable)
        x = x.columns
      end

      raise "Don't know how to append a #{x.class}" unless x.is_a?(BasicGrid)
      raise 'Mismatch in column names' unless colnames.sort == x.keys.sort

      x.each do |k, v|
        v = v.to_a if v.is_a? NArray
        new_values[k] += v
      end
    end

    return self if new_values.empty?

    new_rows = nrows + new_values.first[1].length
    new_values.each do |k, v|
      new_col = Column.make(@columns[k].to_a + v, k)
      @columns[k] = new_col
    end
    self
  end

end
