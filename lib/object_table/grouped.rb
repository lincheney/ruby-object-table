require_relative 'group'
require_relative 'table_child'

class ObjectTable::Grouped
  DEFAULT_VALUE_PREFIX = 'v_'
  include ObjectTable::TableChild

  def initialize(parent, *names, &grouper)
    @parent = parent
    @grouper = grouper
    @names = names
  end

  def _groups
    names, keys = _keys()
    groups = keys.length.times.group_by{|i| keys[i]}
    [names, groups]
  end

  def _keys
    unless @names.empty?
      keys = @names.map{|n| @parent.get_column(n).to_a}.transpose
      return [@names, keys]
    end

    keys = @parent.apply(&@grouper)
    raise 'Group keys must be hashes' unless keys.is_a?(Hash)
    keys = ObjectTable::BasicGrid.new.replace keys
    keys._ensure_uniform_columns!(@parent.nrows)

    [keys.keys, keys.values.map(&:to_a).transpose]
  end

  def each(&block)
    names, groups = _groups()
    return to_enum(:_make_groups, names, groups) unless block
    _make_groups(names, groups){|grp| grp._apply_block(&block)}
  end

  def apply(&block)
    names, groups = _groups()
    value_key = self.class._generate_name(DEFAULT_VALUE_PREFIX, names).to_sym
    nrows = []

    data = to_enum(:_make_groups, names, groups).map do |group|
      value = group._apply_block(&block)

      case value
      when ObjectTable::TableMethods
        nrows.push(value.nrows)
        value = value.columns
      when ObjectTable::BasicGrid
        nrows.push(value._ensure_uniform_columns!)
      else
        nrows.push( (ObjectTable::Column.length_of(value) rescue 1) )
      end

      value = ObjectTable::BasicGrid[value_key, value] unless value.is_a?(ObjectTable::BasicGrid)
      value
    end

    if groups.empty?
      # empty table, so make all keys empty
      keys = ObjectTable::BasicGrid[names.zip([[]] * names.length)]
    else
      keys = groups.keys.transpose.map{|col| col.zip(nrows).flat_map{|key, rows| [key] * rows}}
      keys = ObjectTable::BasicGrid[names.zip(keys)]
    end

    result = __table_cls__._stack(data)
    __table_cls__.new(keys.merge!(result.columns))
  end

  def reduce(&block)
    names, keys = _keys()
    data = ObjectTable::Group::Grid.new(names, keys)

    keys.zip(@parent.each_row(row_struct: data.row_struct)) do |k, row|
      data.eval_block(k, row, block)
    end

    keys = ObjectTable::BasicGrid[names.zip(data.index.keys.transpose)]
    d = data.index.values
    __table_cls__.new(keys.merge!(Hash[data.hash.map{|k, v| [k, v.values_at(*d)]}]))
  end

  def _make_groups(names, groups)
    key_struct = Struct.new(*names.map(&:to_sym))
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

end
