require_relative 'factory'
require_relative 'util'
require_relative 'static_view'
require_relative 'grouping/grid'

class ObjectTable
  class Group < StaticView
    attr_reader :K
    def initialize(parent, keys, value)
      super(parent, value)
      @K = keys
    end
  end

  class Grouping
    DEFAULT_VALUE_PREFIX = 'v_'.freeze
    include Factory::SubFactory

    def initialize(parent, *columns, &grouper)
      @parent = parent
      @grouper = grouper
      @columns = columns
      @names = columns
    end

    def _keys
      return Util.get_rows(@parent, @columns) unless @columns.empty?

      keys = @parent.apply(&@grouper)
      raise 'Group keys must be hashes' unless keys.is_a?(Hash)
      keys = BasicGrid.new.replace keys
      keys._ensure_uniform_columns!(@parent.nrows)

      @names = keys.keys
      keys.values.map(&:to_a).transpose
    end

    def each(&block)
      groups = Util.group_indices(_keys)
      return to_enum(:_make_groups, groups) unless block
      _make_groups(groups){|grp| Util.apply_block(grp, block)}
    end

    def apply(&block)
      groups = Util.group_indices(_keys)
      return empty_aggregation if groups.empty?

      value_key = self.class.generate_name(DEFAULT_VALUE_PREFIX, @names).to_sym
      keys = []

      data = groups.keys.zip(to_enum(:_make_groups, groups)).map do |key, group|
        value = Util.apply_block(group, block)

        case value
        when TableMethods
          nrows = value.nrows
        when BasicGrid
          nrows = value._ensure_uniform_columns!
        else
          nrows = (Column.length_of(value) or 1)
          value = BasicGrid[value_key, value]
        end

        keys.concat( Array.new(nrows, key) )
        value
      end

      keys = BasicGrid[@names.zip(keys.transpose)]
      result = __table_cls__._stack(data)
      __table_cls__.new(keys.merge!(result.columns))
    end

    def reduce(defaults={}, &block)
      keys = _keys()
      return empty_aggregation if keys.empty?

      grid = Grid.new(keys, defaults)
      rows = @parent.each_row(row_factory: Grid::RowFactory)
      grid.apply_to_rows(rows, self.class.key_struct(@names), block)

      keys = BasicGrid[@names.zip(grid.index.keys.transpose)]
      __table_cls__.new(keys.merge!(grid.values))
    end

    def _make_groups(groups)
      key_struct = self.class.key_struct(@names)
      groups.each do |k, v|
        yield __group_cls__.new(@parent, key_struct.new(*k), NArray.to_na(v))
      end
      @parent
    end

    def self.generate_name(prefix, names)
      regex = Regexp.new(Regexp.quote(prefix) + '(\d+)')
      i = names.map{|n| n =~ regex and $1.to_i}.compact.max || -1
      "#{prefix}#{i + 1}"
    end

    def self.key_struct(names)
      Struct.new(*names.map(&:to_sym))
    end

    def empty_aggregation
      __table_cls__.new(@names.map{|n| [n, []]})
    end

  end

end
