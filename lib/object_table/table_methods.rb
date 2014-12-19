module ObjectTable::TableMethods

  def colnames
    columns.keys
  end

  def nrows
    columns.values.first.length
  end

  def ncols
    columns.keys.length
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