require "object_table/version"
require "object_table/basic_grid"
require "object_table/table_methods"
require "object_table/column"
require 'narray'

class ObjectTable
  include TableMethods

  attr_reader :columns

  def initialize(columns = {})
    @columns = BasicGrid[columns]
    @columns.ensure_uniform_columns!

    @columns.each do |k, v|
      @columns[k] = Column.make(v, k)
    end
  end

end
