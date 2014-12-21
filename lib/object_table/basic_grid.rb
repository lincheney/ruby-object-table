require 'narray'

class ObjectTable::BasicGrid < Hash
  ARRAY_LIKE = [Array, NArray, Range]

  def self.[](*args)
    grid = super
    grid._ensure_uniform_columns!
  end

  def _ensure_uniform_columns!(rows = nil)
    arrays, scalars = partition{|k, v| ARRAY_LIKE.any?{|cls| v.is_a?(cls)} }

    unique_rows = arrays.map(&:last).map(&:size).uniq

    if rows
      raise "Differing number of rows: #{unique_rows}" unless unique_rows.empty? or unique_rows == [rows]
    else
      raise "Differing number of rows: #{unique_rows}" if unique_rows.length > 1
      rows = (unique_rows[0] or 1)
    end

    scalars.each do |k, v|
      self[k] = [v] * rows
    end

    self
  end
end
