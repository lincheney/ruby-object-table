require 'narray'

class ObjectTable::BasicGrid < Hash
  ARRAY_LIKE = [Array, NArray]

  def ensure_uniform_columns
    arrays, scalars = partition{|k, v| ARRAY_LIKE.any?{|cls| v.is_a?(cls)} }

    rows = arrays.map(&:last).map(&:length).uniq
    if rows.length > 1
      raise "Differing number of rows: #{rows.uniq}"
    end
    rows = (rows[0] or 1)

    scalars.each do |k, v|
      self[k] = [v] * rows
    end

    self
  end
end
