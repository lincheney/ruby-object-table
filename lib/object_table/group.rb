require_relative 'static_view'
require_relative 'util'

class ObjectTable::Group < ObjectTable::StaticView
  attr_reader :K

  def initialize(parent, keys, value)
    super(parent, value)
    @K = keys
  end

  class Grid
    attr_reader :hash, :index

    def initialize(keys, defaults)
      unless defaults.is_a? Hash
        raise "Expected defaults to be a hash, got: #{defaults.inspect}"
      end
      defaults.default = 0
      @defaults = defaults

      @hash = {}
      @index = Hash[keys.each_with_index.to_a]
      @length = keys.length
    end

    def [](k)
      (@hash[k] ||= Array.new(@length, @defaults[k]))[@key]
    end

    def []=(k, v)
      @hash[k][@key] = v
    end

    def row_struct
      Class.new(Struct){ attr_accessor :K, :R }
    end

    def eval_block(key, struct, row, block)
      @key = @index[key]
      row.K = struct
      row.R = self
      ObjectTable::Util.apply_block(row, block)
    end

  end

end
