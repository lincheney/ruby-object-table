require_relative 'util'

class ObjectTable
  module Joining

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

        if type == 'right' or type == 'outer'
          missing = NArray.int(right.nrows + 1).fill!(1)
          missing[rindex] = 0
          missing[-1] = 0
          missing = missing.where
          rindex.concat( missing.to_a )
          lindex.fill(-1, lindex.length ... (lindex.length + missing.length))
        end

        index = [lindex, rindex].map{|ix| NArray.to_na(ix)}
        blanks = index.map{|ix| ix.eq(-1).where}

        colnames = [left.colnames, right.colnames - left.colnames]
        data = [left, right].zip(index, blanks).zip(colnames).flat_map do |args, cols|
          cols.map{|k| [k, Joining.copy_column(k, *args)] }
        end

        table = __table_cls__.new(data)
        unless blanks[0].empty?
          keys.each do |k|
            table[k][false, blanks[0]] = right[k][false, missing]
          end
        end

        table
      end
    end

    def self.copy_column(name, table, slice, blanks)
      column = table[name][false, slice]
      column[false, blanks] = [nil]
      column
    end

  end

end
