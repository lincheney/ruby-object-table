module ObjectTable::Stacker

  def stack!(*others)
    @columns.replace( ObjectTable::Stacker::ClassMethods.stack(self, *others).columns )
    self
  end

  module ClassMethods
    def stack(*grids)
      keys = nil

      grids = grids.map do |grid|
        grid = _process_stackable_grid(grid, keys)
        keys ||= grid.keys if grid
        grid
      end.compact

      return self.new if grids.empty?

      result = keys.map do |k|
        segments = grids.map{|grid| NArray.to_na grid[k]}
        column = ObjectTable::Column.stack(*segments)
        [k, column]
      end

      self.new(ObjectTable::BasicGrid[result])
    end

    def _process_stackable_grid(grid, keys)
      case grid
      when ObjectTable::TableMethods
        grid = grid.columns
      when ObjectTable::BasicGrid
        grid._ensure_uniform_columns!
      end

      raise "Don't know how to join a #{grid.class}" unless grid.is_a?(ObjectTable::BasicGrid)
      return if grid.empty?
      raise 'Mismatch in column names' unless !keys or ( (keys - grid.keys).empty? and (grid.keys - keys).empty? )
      return grid
    end

  end


  def self.included(base)
    base.extend(ClassMethods)
  end

end
