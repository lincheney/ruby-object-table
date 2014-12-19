module ObjectTable::TableMethods

  def __setup__
    @R = ObjectTable::BasicGrid
  end

  def ==(other)
    return false unless other.is_a?(ObjectTable) or other.is_a?(ObjectTable::View)
    return columns == other.columns
  end

  def colnames
    columns.keys
  end

  def nrows
    columns.values.first.length
  end

  def ncols
    columns.keys.length
  end

  def [](name)
    columns[name]
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

  def group(&block)
    ObjectTable::Grouped.new(self, &block)
  end

  def method_missing(meth, *args, &block)
    columns[meth] or super
  end

  def respond_to?(meth)
    super or columns.include?(meth)
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