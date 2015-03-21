module ObjectTable::Stacker

  def stack!(*others)
    others = others.map do |grid|
      case grid
      when ObjectTable::TableMethods
        grid = grid.columns
      when ObjectTable::BasicGrid
        grid._ensure_uniform_columns!
      end

      raise "Don't know how to append a #{grid.class}" unless grid.is_a?(ObjectTable::BasicGrid)
      next if grid.empty?
      raise 'Mismatch in column names' unless (colnames - grid.keys).empty? and (grid.keys - colnames).empty?
      grid
    end.compact

    return self if others.empty?

    @columns.each do |k, v|
      grids = others.map{|grid| NArray.to_na(grid[k])}
      @columns[k] = ObjectTable::Column.stack(v, *grids)
    end
    self
  end

  module ClassMethods
    def stack(*values)
      return self.new if values.empty?
      base = values.shift

      case base
      when ObjectTable::BasicGrid
        base = self.new(base.clone)
      when ObjectTable, ObjectTable::View
        base = base.clone
      else
        raise "Don't know how to join a #{base.class}"
      end
      base.stack!(*values)
    end
  end


  def self.included(base)
    base.extend(ClassMethods)
  end

end