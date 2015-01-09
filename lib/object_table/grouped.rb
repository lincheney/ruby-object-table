require_relative 'group'

class ObjectTable::Grouped
  DEFAULT_VALUE_PREFIX = 'v_'

  def initialize(parent, names, groups)
    @parent = parent
    @names = names
    @groups = groups
  end

  def each(&block)
    group_cls = @parent.class::Table::Group

    @groups.each do |k, v|
      names = @names.zip(k)
      group_cls.new(@parent, Hash[names], v).apply &block
    end
    @parent
  end

  def apply(&block)
    table_cls = @parent.class::Table
    group_cls = table_cls::Group
    value_key = self.class._generate_name(DEFAULT_VALUE_PREFIX, @names).to_sym

    data = @groups.map do |k, v|
      names = @names.zip(k)
      value = group_cls.new(@parent, Hash[names], v).apply &block

      if value.is_a?(ObjectTable::TableMethods)
        value = value.columns
      end

      grid = case value
      when ObjectTable::BasicGrid
        ObjectTable::BasicGrid[names].merge!(value)
      else
        ObjectTable::BasicGrid[names + [[value_key, value]]]
      end
      grid._ensure_uniform_columns!
    end

    table_cls.stack(*data)
  end

  def self._generate_name(prefix, existing_names)
    regex = Regexp.new(Regexp.quote(prefix) + '(\d+)')
    i = existing_names.map(&regex.method(:match)).compact.map{|match| match[-1].to_i}.max || -1
    "#{prefix}#{i + 1}"
  end

end
