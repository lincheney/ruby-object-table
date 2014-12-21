require_relative 'view'

class ObjectTable::Grouped
  DEFAULT_VALUE_PREFIX = 'v_'

  def initialize(parent, &grouper)
    @parent = parent
    @grouper = grouper
  end

  def each(&block)
    groups.each do |k, v|
      ObjectTable::View.new(@parent, mask: v).instance_eval &block
    end
    @parent
  end

  def apply(&block)
    groups
    value_key = self.class._generate_key(DEFAULT_VALUE_PREFIX, @keys).to_sym

    data = groups.map do |k, v|
      value = ObjectTable::View.new(@parent, mask: v).instance_eval &block
      keys = @keys.zip(k)

      if value.is_a?(ObjectTable::TableMethods)
        value = value.columns
      end

      grid = case value
      when ObjectTable::BasicGrid
        ObjectTable::BasicGrid[keys].merge!(value)
      else
        ObjectTable::BasicGrid[keys + [[value_key, value]]]
      end
      grid._ensure_uniform_columns!
    end

    ObjectTable.stack(*data)
  end

  def groups
    @groups ||= begin
      groups = (0...@parent.nrows).zip(groupers).group_by{|row, value| value}
      groups.each do |k, v|
        groups[k] = v.map &:first
      end
      groups
    end
  end

  def groupers
    @groupers ||= begin
      groupers = @parent.instance_eval(&@grouper)
      raise 'Groups must be a hash' unless groupers.is_a?(Hash)
      @keys = groupers.keys

      groupers = ObjectTable::BasicGrid.new.replace groupers
      groupers._ensure_uniform_columns!(@parent.nrows)
      groupers = groupers.values.map(&:to_a).transpose
      groupers
    end
  end

  def self._generate_key(prefix, existing_keys)
    regex = Regexp.new(Regexp.quote(prefix) + '(\d+)')
    i = existing_keys.map(&regex.method(:match)).compact.map{|match| match[-1].to_i}.max || -1
    "#{prefix}#{i + 1}"
  end

end
