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
    @groupers ||= @parent.instance_eval(&@grouper)
  end
end
