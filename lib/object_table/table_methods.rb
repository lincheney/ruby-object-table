require 'forwardable'

module ObjectTable::TableMethods
  extend Forwardable
  def_delegators :@columns, :[]

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
    columns.values.first.length
  end

  def ncols
    columns.keys.length
  end

  def []=(name, value)
    column = columns[name]
    unless column
      column = add_column(name)
    end
    column[] = value
  end

  def add_column(name)
    columns[name] = ObjectTable::Column.object(nrows)
  end

  def apply(&block)
    result = instance_eval &block
    if result.is_a? ObjectTable::BasicGrid
      result = ObjectTable.new(result)
    end
    result
  end

  def where(&block)
    ObjectTable::View.new(self, &block)
  end

  def group(*args, &block)
    ObjectTable::Grouped.new(self, *args, &block)
  end

  def sort_by(*keys)
    sort_index = _get_sort_index(keys)
    cols = ObjectTable::BasicGrid[columns.map{|k, v| [k, v[sort_index]]}]
    self.class.new(cols)
  end

  def method_missing(meth, *args, &block)
    columns[meth] or super
  end

  def respond_to?(meth)
    super or columns.include?(meth)
  end

  def inspect(max_section = 5)
    header = "#{self.class}(#{nrows}, #{ncols})\n"
    printed_columns = []

    if nrows > max_section * 2
      head = (0...max_section)
      tail = ((nrows - max_section)...nrows)

      printed_columns.push [''] + (head.to_a + tail.to_a).map{|i| "#{i}: "} + ['']
      printed_columns += columns.map do |name, c|
        [name.to_s] + c[[head, tail]].to_a.map(&:inspect) + [name.to_s]
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