class ObjectTable
  module Printing

    def inspect(max_section=5, col_padding=2)
      header = "#{self.class}(#{nrows}, #{ncols})\n"

      return "#{header}(empty table)" if ncols == 0
      return "#{header}(empty table with columns: #{colnames.join(", ")})" if nrows == 0

      separated = (nrows > max_section * 2)
      max_section = (nrows / 2.0) unless separated

      head = Printing.format_section(columns, 0...max_section.to_i).transpose[0...-1]
      tail = Printing.format_section(columns, (nrows - max_section).to_i...nrows).transpose[1..-1]
      widths = Printing.calc_column_widths(head + tail, col_padding)

      rows = Printing.format_rows(head, widths)
      rows.push('-' * widths.reduce(:+)) if separated
      rows.concat Printing.format_rows(tail, widths)

      header + rows.join("\n")

    rescue NoMethodError => e
      raise Exception.new(e)
    end


    def self.format_column(column)
      return column.to_a.map(&:inspect) if column.rank < 2
      column.shape[-1].times.map do |i|
        row = column[false, i]
        row.inspect.partition("\n")[-1].strip
      end
    end

    def self.split_column_lines(name, column)
      [name, *column, name].map{|i| i.split("\n")}
    end

    def self.calc_column_widths(rows, padding)
      columns = rows.transpose
      columns.map{|col| col.flatten.map(&:length).max + padding}
    end

    def self.format_rows(rows, widths)
      rows = rows.flat_map do |row|
        height = row.map(&:length).max
        row.map{|cell| cell.fill('', cell.length...height)}.transpose
      end

      format = widths.to_a.map{|w| "%#{w}s"}.join
      rows.map{|row| format % row }
    end

    def self.format_section(columns, row_slice)
      row_slice = row_slice.to_a
      numbers = split_column_lines('', row_slice.map{|i| "#{i}: "})

      section = columns.map do |name, c|
        c = (row_slice.empty? ? NArray[] : c.slice(false, row_slice))
        c = format_column(c)
        c = split_column_lines(name.to_s, c)
      end

      [numbers] + section
    end

  end
end
