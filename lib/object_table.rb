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

  def join(other, *key, type: 'inner')
    right_cols = other.colnames - key
    left_cols = colnames

    lkeys = key.map{|k| get_column(k).to_a}.transpose
    rkeys = key.map{|k| other[k].to_a}.transpose

    rgroups = rkeys.length.times.group_by{|i| rkeys[i]}
    rindex = rgroups.values_at(*lkeys)

    if type == 'left' or type == 'outer'
      common, missing = rindex.each_with_index.partition(&:first)
      missing = missing.transpose[-1]
      rindex = rindex.compact!.flatten
      lindex = common.flat_map{|r, i| r.fill(i)}

      lindex.concat( missing )
      rindex.concat( missing.fill(-1) )
    else
      lindex = rindex
      rindex = rindex.compact.flatten
      lindex = lindex.each_with_index.flat_map{|r, i| r.fill(i) if r}.compact
    end

    lmissing = (type == 'right' or type == 'outer')
    if lmissing
      missing = NArray.int(other.nrows)
      missing[rindex] = -1
      missing = missing.ne(-1).where.to_a
      rindex.concat( missing )
      lindex.concat( missing.fill(-1) )
    end

    lindex = NArray.to_na(lindex)
    rindex = NArray.to_na(rindex)
    lblank = lindex.eq(-1).where
    rblank = rindex.eq(-1).where

    data = [
      [left_cols, lindex, lblank, self],
      [right_cols, rindex, rblank, other],
    ].flat_map do |cols, index, blanks, table|
      cols.map do |k|
        col = table[k][false, index]
        col[false, blanks] = [nil]
        [k, col]
      end
    end

    table = __table_cls__.new(data)
    if lmissing
      i = rindex[lblank]
      key.each do |k|
        table[k][false, lblank] = other[k][false, i]
      end
    end

    table
  end

end
