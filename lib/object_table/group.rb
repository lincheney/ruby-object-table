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

    def initialize(names, keys)
      @hash = {}
      @index = Hash[keys.each_with_index.to_a]
      @length = keys.length
      @key_struct = Struct.new(*names.map(&:to_sym))
    end

    def [](k)
      (@hash[k] ||= Array.new(@length, 0))[@key]
    end

    def []=(k, v)
      @hash[k][@key] = v
    end

    def row_struct
      Class.new(Struct){ attr_accessor :K, :R }
    end

    def eval_block(key, row, block)
      @key = @index[key]
      row.K = @key_struct.new(*key)
      row.R = self
      ObjectTable::Util.apply_block(row, block)
    end

  end

end
