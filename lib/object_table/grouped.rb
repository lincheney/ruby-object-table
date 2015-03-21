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
    groups.each do |k, v|
      groups[k] = v
    end
    [names, groups]
  end

  def _keys
    if @names.empty?
      keys = @parent.apply(&@grouper)
      raise 'Group keys must be hashes' unless keys.is_a?(Hash)
      keys = ObjectTable::BasicGrid.new.replace keys
      keys._ensure_uniform_columns!(@parent.nrows)
    else
      keys = ObjectTable::BasicGrid[@names.map{|n| [n, @parent.get_column(n)]}]
    end

    names = keys.keys
    keys = keys.values.map(&:to_a).transpose
    [names, keys]
  end

  def each(&block)
    names, groups = _groups()
    enumerator = _make_groups(names, groups)
    return enumerator unless block
    enumerator.each{|grp| grp._apply_block(&block)}
  end

  def apply(&block)
    names, groups = _groups()
    value_key = self.class._generate_name(DEFAULT_VALUE_PREFIX, names).to_sym
    nrows = []

    data = _make_groups(names, groups).map do |group|
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

    keys = groups.keys.transpose.map{|col| col.zip(nrows).flat_map{|key, rows| [key] * rows}}
    keys = ObjectTable::BasicGrid[names.zip(keys)]

    result = __table_cls__.stack(*data)
    __table_cls__.new(keys.merge!(result.columns))
  end


  def _make_groups(names, groups)
    key_struct = Struct.new(*names.map(&:to_sym))
    enumerator = Enumerator.new do |y|
      groups.each do |k, v|
        y.yield __group_cls__.new(@parent, key_struct.new(*k), v)
      end
      @parent
    end
  end

  def self._generate_name(prefix, existing_names)
    regex = Regexp.new(Regexp.quote(prefix) + '(\d+)')
    i = existing_names.map(&regex.method(:match)).compact.map{|match| match[-1].to_i}.max || -1
    "#{prefix}#{i + 1}"
  end

end
