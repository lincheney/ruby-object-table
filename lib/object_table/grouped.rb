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

    enumerator = Enumerator.new do |y|
      groups.each do |k, v|
        keys = names.zip(k)
        y.yield __group_cls__.new(@parent, Hash[keys], v)
      end
      @parent
    end

    return enumerator unless block
    enumerator.each{|grp| grp._apply_block(&block)}
  end

  def apply(&block)
    names, groups = _groups()
    value_key = self.class._generate_name(DEFAULT_VALUE_PREFIX, names).to_sym

    data = groups.map do |k, v|
      keys = names.zip(k)
      value = __group_cls__.new(@parent, Hash[keys], v)._apply_block &block

      case value
      when ObjectTable::TableMethods
        nrows = value.nrows
        value = value.columns
      when ObjectTable::BasicGrid
        value._ensure_uniform_columns!
        nrows = NArray.to_na(value.values.first).shape[-1]
      when Array
        nrows = value.length
      when NArray
        nrows = value.shape.last
      else
        nrows = 1
      end

      keys = names.zip(k.map{|x| [x] * nrows})

      grid = case value
      when ObjectTable::BasicGrid
        ObjectTable::BasicGrid[keys].merge!(value)
      else
        ObjectTable::BasicGrid[keys + [[value_key, value]]]
      end
    end

    __table_cls__.stack(*data)
  end

  def self._generate_name(prefix, existing_names)
    regex = Regexp.new(Regexp.quote(prefix) + '(\d+)')
    i = existing_names.map(&regex.method(:match)).compact.map{|match| match[-1].to_i}.max || -1
    "#{prefix}#{i + 1}"
  end

end
