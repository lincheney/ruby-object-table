require 'narray'

class ObjectTable::BasicGrid < Hash
  ARRAY_LIKE = [Array, NArray]

  def self.[](*args)
    grid = super
    grid._ensure_uniform_columns!
  end

  def _ensure_uniform_columns!
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

  def _next_available_key(prefix)
    regex = Regexp.new(Regexp.quote(prefix) + '(\d+)')
    index = keys.map(&regex.method(:match)).compact.map{|match| match[-1].to_i}.max || -1
    "#{prefix}#{index + 1}"
  end
end
