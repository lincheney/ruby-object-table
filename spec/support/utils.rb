def make_table(table, cls)
  case [cls]
  when [ObjectTable] then table
  when [ObjectTable::View] then table.where{true}
  when [ObjectTable::StaticView] then table.where{true}.apply{self}
  else nil
  end
end