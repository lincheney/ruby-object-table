require 'forwardable'

module ObjectTable::TableMethods
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
    columns.values.first.shape[-1]
  end

  def ncols
    columns.keys.length
  end

  def_delegator :columns, :include?, :has_column?

  def_delegator :columns, :[], :get_column
  alias_method :[], :get_column

  def set_column(name, value, *args, column: nil)
    column ||= get_column(name)
    value = value.to_a if value.is_a?(Range)

    if column
      return (column[] = value)
    end

    if (value.is_a?(Array) or value.is_a?(NArray)) and args.empty?
      value =  NArray.to_na(value)
      unless value.shape[-1] == nrows
        raise ArgumentError.new("Expected size of last dimension to be #{nrows}, was #{value.shape[-1]}")
      end

      args = [value.typecode] + value.shape[0...-1]
    end

    column = add_column(name, *args)
    begin
      column[] = value
    rescue Exception => e
      pop_column(name)
      raise e
    end
  end
  alias_method :[]=, :set_column

  def pop_column(name)
    columns.delete name
  end

  def apply(&block)
    result = instance_eval &block
    if result.is_a? ObjectTable::BasicGrid
      result = ObjectTable.new(result)
    end
    result
  end

  def where(&block)
    ObjectTable::TempView.new(self, &block)
  end

  def group(*args, &block)
    ObjectTable::TempGrouped.new(self, *args, &block)
  end

  def sort_by(*keys)
    sort_index = _get_sort_index(keys)
    cols = ObjectTable::BasicGrid[columns.map{|k, v| [k, v[sort_index]]}]
    ObjectTable.new(cols)
  end

  def method_missing(meth, *args, &block)
    get_column(meth) or super
  end

  def respond_to?(meth)
    super or has_column?(meth)
  end

  def inspect(max_section = 5)
    header = "#{self.class}(#{nrows}, #{ncols})\n"
    printed_columns = []

    if nrows > max_section * 2
      head = (0...max_section)
      tail = ((nrows - max_section)...nrows)

      printed_columns.push [''] + (head.to_a + tail.to_a).map{|i| "#{i}: "} + ['']
      printed_columns += columns.map do |name, c|
        padded_dims = [nil] * (c.rank - 1)
        [name.to_s] + c.slice(*padded_dims, [head, tail]).to_a.map(&:inspect) + [name.to_s]
      end
    else
      max_section = -1
      printed_columns.push [''] + (0...nrows).map{|i| "#{i}: "} + ['']
      printed_columns += columns.map do |name, c|
        [name.to_s] + c.to_a.map(&:inspect) + [name.to_s]
      end
    end

    widths = printed_columns.map{|col| col.map(&:length).max + 2}

    header + printed_columns.transpose.each_with_index.map do |row, index|
      row = row.zip(widths).map do |cell, width|
        cell.rjust(width)
      end.join('')

      if index == max_section
        row += "\n" + '-'*widths.reduce(:+)
      end
      row
    end.join("\n")
  end

  def clone
    cols = ObjectTable::BasicGrid[columns.map{|k, v| [k, v.clone]}]
    ObjectTable.new(cols)
  end

  def _get_sort_index(columns)
    (0...nrows).zip(columns.map(&:to_a).transpose).sort_by(&:last).map(&:first)
  end

end
