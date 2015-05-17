require_relative 'util'

module ObjectTable::Joining
  Util = ObjectTable::Util

  def join(*args)
    __table_cls__.join(self, *args)
  end

  module ClassMethods
    def join(left, right, *keys, type: 'inner')
      lkeys = Util.get_rows(left, keys)
      rkeys = Util.get_rows(right, keys)

      rgroups = Util.group_indices(rkeys)
      if type == 'left' or type == 'outer'
        rgroups.default = [-1]
      else
        rgroups.default = []
      end

      lindex = rgroups.values_at(*lkeys)
      rindex = lindex.flatten
      lindex = lindex.each_with_index.flat_map{|r, i| r.fill(i)}

      lmissing = (type == 'right' or type == 'outer')
      if lmissing
        missing = NArray.int(right.nrows + 1).fill!(1)
        missing[rindex] = 0
        missing[-1] = 0
        missing = missing.where.to_a
        rindex.concat( missing )
        lindex.concat( missing.fill(-1) )
      end

      lindex = NArray.to_na(lindex)
      rindex = NArray.to_na(rindex)
      lblank = lindex.eq(-1).where
      rblank = rindex.eq(-1).where
      blank = [nil]

      data = [
        [left.colnames, lindex, lblank, left],
        [right.colnames - keys, rindex, rblank, right],
      ].flat_map do |cols, index, blanks, table|
        cols.map do |k|
          col = table[k][false, index]
          col[false, blanks] = blank
          [k, col]
        end
      end

      table = __table_cls__.new(data)
      if lmissing
        i = rindex[lblank]
        keys.each do |k|
          table[k][false, lblank] = right[k][false, i]
        end
      end

      table
    end
  end

end