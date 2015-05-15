require_relative 'group'
require_relative 'factory'
require_relative 'util'

class ObjectTable::Grouped
  DEFAULT_VALUE_PREFIX = 'v_'.freeze
  include ObjectTable::Factory::SubFactory
  Util = ObjectTable::Util

  def initialize(parent, *columns, &grouper)
    @parent = parent
    @grouper = grouper
    @columns = columns
    @names = columns
  end

  def _groups
    keys = _keys()
    keys.length.times.group_by{|i| keys[i]}
  end

  def _keys
    unless @columns.empty?
      return @columns.map{|n| @parent.get_column(n).to_a}.transpose
    end

    keys = @parent.apply(&@grouper)
    raise 'Group keys must be hashes' unless keys.is_a?(Hash)
    keys = ObjectTable::BasicGrid.new.replace keys
    keys._ensure_uniform_columns!(@parent.nrows)

    @names = keys.keys
    keys.values.map(&:to_a).transpose
  end

  def each(&block)
    groups = _groups()
    return to_enum(:_make_groups, groups) unless block
    _make_groups(groups){|grp| Util.apply_block(grp, block)}
  end

  def apply(&block)
    groups = _groups()
    return empty_aggregation if groups.empty?

    value_key = self.class._generate_name(DEFAULT_VALUE_PREFIX, @names).to_sym
    keys = []

    data = groups.keys.zip(to_enum(:_make_groups, groups)).map do |key, group|
      value = Util.apply_block(group, block)

      case value
      when ObjectTable::TableMethods
        nrows = value.nrows
        value = value.columns
      when ObjectTable::BasicGrid
        nrows = value._ensure_uniform_columns!
      else
        nrows = (ObjectTable::Column.length_of(value) or 1)
      end

      keys.concat( [key] * nrows )
      value = ObjectTable::BasicGrid[value_key, value] unless value.is_a?(ObjectTable::BasicGrid)
      value
    end

    keys = ObjectTable::BasicGrid[@names.zip(keys.transpose)]
    result = __table_cls__._stack(data)
    __table_cls__.new(keys.merge!(result.columns))
  end

  def reduce(defaults={}, &block)
    keys = _keys()
    return empty_aggregation if keys.empty?

    grid = ObjectTable::Group::Grid.new(keys, defaults)
    rows = @parent.each_row(row_struct: grid.row_struct)
    grid.apply_to_rows(rows, key_struct, block)

    keys = ObjectTable::BasicGrid[@names.zip(grid.index.keys.transpose)]
    __table_cls__.new(keys.merge!(Hash[grid.values]))
  end

  def _make_groups(groups)
    key_struct = key_struct()
    groups.each do |k, v|
      yield __group_cls__.new(@parent, key_struct.new(*k), v)
    end
    @parent
  end

  def self._generate_name(prefix, existing_names)
    regex = Regexp.new(Regexp.quote(prefix) + '(\d+)')
    i = existing_names.map(&regex.method(:match)).compact.map{|match| match[-1].to_i}.max || -1
    "#{prefix}#{i + 1}"
  end

  def key_struct
    Struct.new(*@names.map(&:to_sym))
  end

  def empty_aggregation
    __table_cls__.new(@names.zip(Array.new(@names.length, [])))
  end

end
