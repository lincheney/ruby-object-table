require 'forwardable'
require_relative 'printable'
require_relative 'util'

module ObjectTable::TableMethods
  include ObjectTable::Printable
  extend Forwardable
  Util = ObjectTable::Util

  attr_reader :R
  def initialize
    @R = ObjectTable::BasicGrid
  end

  def ==(other)
    return false unless other.is_a?(ObjectTable::TableMethods)
    return columns == other.columns
  end
  alias_method :eql?, :==

  def nrows
    columns.empty? ? 0 : (columns.first[1].shape[-1] or 0)
  end

  def ncols
    columns.keys.length
  end

  def_delegator :columns, :keys, :colnames
  def_delegator :columns, :include?, :has_column?
  def_delegator :columns, :delete, :pop_column
  def_delegator :columns, :[], :get_column
  alias_method :[], :get_column

  def set_column(name, value, *args)
    column = get_column(name)
    new_column = column.nil?

    value = value.to_a if value.is_a?(Range)
    is_vector = (value.is_a?(Array) or value.is_a?(NArray))

    if new_column
      if is_vector and args.empty?
        value =  NArray.to_na(value)
        unless (value.shape[-1] or 0) == nrows
          raise ArgumentError.new("Expected size of last dimension to be #{nrows}, was #{value.shape[-1].inspect}")
        end

        args = [value.typecode] + value.shape[0...-1]
      end

      column = add_column(name, *args)
    end

    return column if column.empty? and (!is_vector or value.empty?)

    begin
      column[] = value
    rescue Exception => e
      pop_column(name) if new_column
      raise e
    end
  end
  alias_method :[]=, :set_column


  def apply(&block)
    result = Util.apply_block(self, block)
    return result unless result.is_a? ObjectTable::BasicGrid
    __table_cls__.new(result)
  end

  def where(&block)
    __view_cls__.new(self, &block)
  end

  def group_by(*args, &block)
    ObjectTable::Grouped.new(self, *args, &block)
  end

  def sort_by(*keys)
    sort_index = _get_sort_index(keys)
    cols = ObjectTable::BasicGrid[columns.map{|k, v| [k, v[sort_index]]}]
    __table_cls__.new(cols)
  end

  def method_missing(meth, *args, &block)
    get_column(meth) or super
  end

  def respond_to?(meth, include_all = false)
    super or has_column?(meth)
  end

  def clone
    cols = ObjectTable::BasicGrid[columns.map{|k, v| [k, v.clone]}]
    __table_cls__.new(cols)
  end

  def _get_sort_index(columns)
    (0...nrows).zip(columns.map(&:to_a).transpose).sort_by(&:last).map(&:first)
  end

  def each_row(*cols, row_struct: Struct)
    return to_enum(:each_row, *cols, row_struct: row_struct ) unless block_given?
    return if ncols == 0

    cls = nil
    if cols.empty?
      cls = row_struct.new(*colnames)
      cols = colnames
    end

    nrows.times do |i|
      row = colnames.map{|c| get_column(c)[false, i]}
      row = cls.new(*row) if cls
      yield row
    end
  end

end
