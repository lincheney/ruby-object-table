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

  def join(other, *keys, type: 'inner')
    lkeys = keys.map{|k| get_column(k).to_a}.transpose
    rkeys = keys.map{|k| other[k].to_a}.transpose

    rgroups = rkeys.length.times.group_by{|i| rkeys[i]}
    if type == 'left' or type == 'outer'
      rgroups.default = [-1]
    else
      rgroups.default = []
    end

    lindex = rgroups.values_at(*lkeys)
    rindex = lindex.flatten
    lindex = lindex.each_with_index.flat_map{|r, i| r.fill(i)}

    lmissing = (type == 'right' or type == 'outer')
    if lmissing
      missing = NArray.int(other.nrows + 1).fill!(1)
      missing[rindex] = 0
      missing[-1] = 0
      missing = missing.where.to_a
      rindex.concat( missing )
      lindex.concat( missing.fill(-1) )
    end

    lindex = NArray.to_na(lindex)
    rindex = NArray.to_na(rindex)
    lblank = lindex.eq(-1).where
    rblank = rindex.eq(-1).where
    blank = [nil]

    data = [
      [colnames, lindex, lblank, self],
      [other.colnames - keys, rindex, rblank, other],
    ].flat_map do |cols, index, blanks, table|
      cols.map do |k|
        col = table[k][false, index]
        col[false, blanks] = blank
        [k, col]
      end
    end

    table = __table_cls__.new(data)
    if lmissing
      i = rindex[lblank]
      keys.each do |k|
        table[k][false, lblank] = other[k][false, i]
      end
    end

    table
  end

end
