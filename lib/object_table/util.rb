module ObjectTable::Util

  def self.apply_block(object, block)
    if block.arity == 0
      object.instance_eval(&block)
    else
      block.call(object)
    end
  end

end