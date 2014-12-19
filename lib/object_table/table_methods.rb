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

end