require 'forwardable'
require_relative 'grouped'

class ObjectTable::TempGrouped
  extend Forwardable
  def_delegators :make_grouped, :each, :apply

  def initialize(parent, *names, &grouper)
    @parent = parent
    @grouper = grouper
    @names = names
  end

  def _groups
    names, keys = _keys()
    groups = (0...@parent.nrows).zip(keys).group_by{|row, key| key}
    groups.each do |k, v|
      groups[k] = NArray.to_na(v.map(&:first))
    end
    [names, groups]
  end

  def _keys
    if @names.empty?
      keys = @parent.instance_eval(&@grouper)
      raise 'Group keys must be hashes' unless keys.is_a?(Hash)
      keys = ObjectTable::BasicGrid.new.replace keys
    else
      keys = ObjectTable::BasicGrid[@names.map{|n| [n, @parent.get_column(n)]}]
    end

    keys._ensure_uniform_columns!(@parent.nrows)
    names = keys.keys
    keys = keys.values.map(&:to_a).transpose
    [names, keys]
  end

  def make_grouped
    names, groups = _groups()
    ObjectTable::Grouped.new(@parent, names, groups)
  end

end
