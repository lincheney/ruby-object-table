require_relative 'view'

class ObjectTable::Grouped
  DEFAULT_VALUE_PREFIX = 'v_'

  def initialize(parent, names, groups)
    @parent = parent
    @names = names
    @groups = groups
  end

  def each(&block)
    @groups.each do |k, v|
      ObjectTable::View.new(@parent, v).apply &block
    end
    @parent
  end

  def apply(&block)
    value_key = self.class._generate_name(DEFAULT_VALUE_PREFIX, @names).to_sym

    data = @groups.map do |k, v|
      value = ObjectTable::View.new(@parent, v).apply &block
      names = @names.zip(k)

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

    ObjectTable.stack(*data)
  end

  def self._generate_name(prefix, existing_names)
    regex = Regexp.new(Regexp.quote(prefix) + '(\d+)')
    i = existing_names.map(&regex.method(:match)).compact.map{|match| match[-1].to_i}.max || -1
    "#{prefix}#{i + 1}"
  end

end
