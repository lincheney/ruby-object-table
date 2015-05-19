require_relative '../util'

class ObjectTable::Grouping

  class Grid
    attr_reader :values, :index

    def initialize(keys, defaults)
      unless defaults.is_a?(Hash)
        raise "Expected defaults to be a hash, got: #{defaults.inspect}"
      end
      defaults.default = 0
      @defaults = defaults

      @values = {}
      @index = {}
      @ids = keys.map{|k| @index[k] ||= @index.length}
      @keys = keys
      @length = @index.length
    end

    def [](k)
      (@values[k] ||= Array.new(@length, @defaults[k]))[@id]
    end

    def []=(k, v)
      @values[k][@id] = v
    end

    module RowFactory
      def self.new(*args)
        Struct.new(*args){ attr_accessor :K, :R }
      end
    end

    def apply_to_rows(rows, key_struct, block)
      @ids.zip(@keys, rows) do |id, key, row|
        @id = id
        row.K = key_struct.new(*key)
        row.R = self
        ObjectTable::Util.apply_block(row, block)
      end
    end

  end

end
