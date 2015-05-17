module ObjectTable::Util

  def self.apply_block(object, block)
    if block.arity == 0
      object.instance_eval(&block)
    else
      block.call(object)
    end
  end

  def self.get_rows(table, columns)
    columns.map{|n| table[n].to_a}.transpose
  end

  def self.group_indices(keys)
    keys.length.times.group_by{|i| keys[i]}
  end

end