require 'narray'

module ObjectTable::Column

  def self.length_of(array)
    case array
    when Array then array.length
    when NArray then (array.shape.last or 0)
    else nil
    end
  end


  def self.stack(*columns)
    columns = columns.reject(&:empty?)
    return NArray[] if columns.empty?
    return columns[0].clone if columns.length == 1

    if columns.map{|x| x.shape}.uniq.length == 1
      new_col = NArray.to_na(columns)
      new_col = new_col.reshape(*new_col.shape[0...-2], new_col.shape[-2] * new_col.shape[-1])
      return new_col
    end

    new_rows = columns.map{|x| x.shape[-1]}.reduce(:+)
    first_col = columns.first
    new_col = NArray.new(first_col.typecode, *first_col.shape[0...-1], new_rows)

    columns.reduce(0) do |row, col|
      end_row = row + col.shape[-1]
      new_col[false, row ... end_row] = col
      end_row
    end

    new_col
  end

end
