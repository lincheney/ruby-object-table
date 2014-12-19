require "object_table/version"
require "object_table/basic_grid"
require "object_table/table_methods"
require 'narray'

class ObjectTable
  include TableMethods

  attr_reader :columns

  def initialize(columns = {})
    @columns = BasicGrid[columns]
    @columns.ensure_uniform_columns!
  end

  def inspect
    header = "#{self.class}(#{nrows}, #{ncols})\n"

    cols = [''] + (0...nrows).map{|i| "#{i}: "} + ['']
    cols = [cols] + columns.map do |name, c|
      [name.to_s] + c.to_a.map(&:inspect) + [name.to_s]
    end
    widths = cols.map{|c| c.map(&:length).max + 2}

    header + cols.transpose.map do |row|
      row.zip(widths).map do |cell, width|
        cell.rjust(width)
      end.join('')
    end.join("\n")
  end

end
