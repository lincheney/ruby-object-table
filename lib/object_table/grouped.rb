require_relative 'view'

class ObjectTable::Grouped
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
    values = groups.map do |k, v|
      value = ObjectTable::View.new(@parent, mask: v).instance_eval &block
      ObjectTable::BasicGrid[@keys.zip(k) + [[:value, value]]]
    end

    ObjectTable.stack(*values)
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
      groupers = groupers.values.map(&:to_a).transpose
      groupers
    end
  end

end
