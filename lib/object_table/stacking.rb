class ObjectTable
  module Stacking

    def stack(*others)
      __table_cls__.stack(self, *others)
    end

    module InPlace
      def stack!(*others)
        @columns.replace( __table_cls__.stack(self, *others).columns )
        self
      end
    end

    module ClassMethods
      def stack(*grids); _stack(grids); end

      def _stack(grids)
        keys = nil

        grids = grids.map do |grid|
          grid = Stacking.process_stackable_grid(grid, keys)
          keys ||= grid.keys if grid
          grid
        end.compact
        return __table_cls__.new if grids.empty?

        result = keys.map do |k|
          segments = grids.map{|grid| grid[k]}
          [k, Stacking.stack_segments(segments)]
        end

        __table_cls__.new(BasicGrid[result])
      end

    end


    def self.stack_segments(segments)
      if segments.all?{|seg| seg.is_a? Array}
        column = NArray.to_na(segments.flatten(1))

      else
        segments.map!{|seg| NArray.to_na seg}
        column = Column._stack(segments)

      end
    end

    def self.process_stackable_grid(grid, keys)
      case grid
      when TableMethods
        grid = grid.columns
      when BasicGrid
        grid._ensure_uniform_columns!
      end

      raise "Don't know how to join a #{grid.class}" unless grid.is_a?(BasicGrid)
      return if grid.empty?
      raise 'Mismatch in column names' unless !keys or ( (keys - grid.keys).empty? and (grid.keys - keys).empty? )
      return grid
    end

  end

end
