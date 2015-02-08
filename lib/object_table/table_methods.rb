require 'forwardable'
require_relative 'printable'

module ObjectTable::TableMethods
  include ObjectTable::Printable
  extend Forwardable

  attr_reader :R
  def initialize
    @R = ObjectTable::BasicGrid
  end

  def ==(other)
    return false unless other.is_a?(ObjectTable::TableMethods)
    return columns == other.columns
  end
  alias_method :eql?, :==

  def colnames
    columns.keys
  end

  def nrows
    columns.empty? ? 0 : (columns.values.first.shape[-1] or 0)
  end

  def ncols
    columns.keys.length
  end

  def_delegator :columns, :include?, :has_column?

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

  def pop_column(name)
    columns.delete name
  end

  def apply(&block)
    result = _apply_block(&block)

    return result unless result.is_a? ObjectTable::BasicGrid
    __table_cls__.new(result)
  end

  def _apply_block(&block)
    if block.arity == 0
      result = instance_eval &block
    else
      result = block.call(self)
    end
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

  def respond_to?(meth)
    super or has_column?(meth)
  end

  def clone
    cols = ObjectTable::BasicGrid[columns.map{|k, v| [k, v.clone]}]
    __table_cls__.new(cols)
  end

  def _get_sort_index(columns)
    (0...nrows).zip(columns.map(&:to_a).transpose).sort_by(&:last).map(&:first)
  end

end
