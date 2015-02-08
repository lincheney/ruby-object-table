require 'narray'

module ObjectTable::Column

  def self.stack(*columns)
    return NArray[] if columns.empty?
    return columns[0].clone if columns.length == 1

    new_rows = columns.map{|x| x.shape[-1]}.reduce(:+)
    first_col = columns.first
    new_col = NArray.new(first_col.typecode, *first_col.shape[0...-1], new_rows)

    row = 0
    columns.each do |col|
      new_col[false, row ... (row + col.shape[-1])] = col
      row += col.shape[-1]
    end

    new_col
  end

end
