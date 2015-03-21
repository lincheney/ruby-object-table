require 'narray'

class ObjectTable::BasicGrid < Hash
#   def self.[](*args)
#     grid = super
#     grid._ensure_uniform_columns!
#   end

  def _get_number_rows!
    each{|k, v| self[k] = v.to_a if v.is_a?(Range)}
    rows = map{|k, v| ObjectTable::Column.length_of(v) rescue nil}.compact.uniq
  end

  def _ensure_uniform_columns!(rows = nil)
    unique_rows = _get_number_rows!
    unique_rows |= [rows] if rows

    raise "Differing number of rows: #{unique_rows}" if unique_rows.length > 1
    rows = (unique_rows[0] or 1)

    each do |k, v|
      self[k] = [v] * rows unless (v.is_a?(Array) || v.is_a?(NArray))
    end

    rows
  end

end
