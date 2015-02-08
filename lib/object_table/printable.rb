module ObjectTable::Printable

  def self.get_printable_column(name, column)
    rows = column.shape[-1].times.map do |i|
      row = column[false, i]
      str = row.is_a?(NArray) ? row.inspect.partition("\n")[-1].strip : row.inspect
      str.split("\n")
    end

    name = name.to_s
    [[name]] + rows + [[name]]
  end

  def self.get_printable_line_numbers(numbers)
    rows = numbers.map do |i|
      ["#{i}: "]
    end

    [['']] + rows + [['']]
  end

  def inspect(max_section = 5, col_padding = 2)
    header = "#{self.class}(#{nrows}, #{ncols})\n"

    return (header + "(empty table)") if ncols == 0
    return (header + "(empty table with columns: #{colnames.join(", ")})") if nrows == 0

    printed_columns = []

    if nrows > max_section * 2
      head = (0...max_section)
      tail = ((nrows - max_section)...nrows)

      printed_columns.push ObjectTable::Printable.get_printable_line_numbers(head.to_a + tail.to_a)

      printed_columns += columns.map do |name, c|
        c = c.slice(false, [head, tail])
        ObjectTable::Printable.get_printable_column(name, c)
      end
    else
      max_section = -1
      printed_columns.push ObjectTable::Printable.get_printable_line_numbers(0...nrows)
      printed_columns += columns.map do |name, c|
        ObjectTable::Printable.get_printable_column(name, c)
      end
    end

    widths = printed_columns.map{|row| row.flat_map{|c| c.map(&:length)}.max + col_padding}

    header + printed_columns.transpose.each_with_index.map do |row, index|
      height = row.map(&:length).max

      row = row.zip(widths).map do |cell, width|
        cell += [" "] * (height - cell.length)
        cell.map{|i| i.rjust(width)}
      end

      row = row.transpose.map{|i| i.join('')}.join("\n")

      if index == max_section
        row += "\n" + '-'*widths.reduce(:+)
      end
      row
    end.join("\n")

  rescue NoMethodError => e
    raise Exception.new(e)
  end

end