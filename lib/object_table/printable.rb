module ObjectTable::Printable

  def self.get_printable_column(column)
    column.shape[-1].times.map do |i|
      row = column[false, i]
      str = row.is_a?(NArray) ? row.inspect.partition("\n")[-1].strip : row.inspect
      str.split("\n")
    end
  end

  def self.calc_column_widths(columns)
    columns.map{|col| col.flatten.map(&:length).max}
  end

  def _format_section(row_slice)
    numbers = row_slice.map{|i| ["#{i}: "]}
    section = columns.map do |name, c|
      c = c.slice(false, row_slice)
      ObjectTable::Printable.get_printable_column(c)
    end

    [numbers] + section
  end

  def _format_rows(rows, widths)
    rows.flat_map do |row|
      height = row.map(&:length).max

      row = row.zip(widths).map do |cell, width|
        cell += [" "] * (height - cell.length)
        cell.map{|i| i.rjust(width)}
      end

      row.transpose.map(&:join)
    end
  end

  def inspect(max_section = 5, col_padding = 2)
    header = "#{self.class}(#{nrows}, #{ncols})\n"

    return (header + "(empty table)") if ncols == 0
    return (header + "(empty table with columns: #{colnames.join(", ")})") if nrows == 0

    column_headers = [''] + colnames.map(&:to_s)

    if nrows > max_section * 2
      head = _format_section(0 ... max_section)
      tail = _format_section((nrows - max_section) ... nrows)

      columns = [column_headers, head, tail].transpose
      widths = NArray.to_na(ObjectTable::Printable.calc_column_widths(columns)) + col_padding
      total_width = widths.sum

      rows = _format_rows(head.transpose, widths)
      rows.push('-' * total_width)
      rows += _format_rows(tail.transpose, widths)

    else
      section = _format_section(0...nrows)
      columns = [column_headers, section].transpose
      widths = NArray.to_na(ObjectTable::Printable.calc_column_widths(columns)) + col_padding
      rows = _format_rows(section.transpose, widths)
    end

    column_headers = _format_rows([[column_headers].transpose], widths).join
    header + ([column_headers] + rows + [column_headers]).join("\n")

  rescue NoMethodError => e
    raise Exception.new(e)
  end

end
