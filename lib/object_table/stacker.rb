module ObjectTable::Stacker

  def stack!(*others)
    new_values = Hash[colnames.zip(ncols.times.map{[]})]

    others.each do |x|
      case x
      when ObjectTable::TableMethods
        x = x.columns
      when ObjectTable::BasicGrid
        x._ensure_uniform_columns!
      end

      raise "Don't know how to append a #{x.class}" unless x.is_a?(ObjectTable::BasicGrid)
      next if x.empty?
      raise 'Mismatch in column names' unless (colnames - x.keys).empty?

      x.each do |k, v|
        unless new_values.include?(k) and v.empty?
          new_values[k].push(NArray.to_na(v))
#           new_values[k].push(v)
        end
      end
    end

    return self if new_values.values.first.empty?

    new_values.each do |k, v|
      @columns[k] = ObjectTable::Column.stack(@columns[k], *v)
    end
    self
  end

  module ClassMethods
    def stack(*values)
      return self.new if values.empty?
      base = values.shift

      case base
      when ObjectTable::BasicGrid
        base = self.new(base.clone)
      when ObjectTable, ObjectTable::View
        base = base.clone
      else
        raise "Don't know how to join a #{base.class}"
      end
      base.stack!(*values)
    end
  end


  def self.included(base)
    base.extend(ClassMethods)
  end

end