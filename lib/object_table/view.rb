require 'forwardable'
require_relative 'view_methods'
require_relative 'masked_column'
require_relative 'util'

class ObjectTable::View
  include ObjectTable::ViewMethods
  Util = ObjectTable::Util

  extend Forwardable
  def_delegators :make_view, :apply

  def initialize(parent, &block)
    super()
    @parent = parent
    @filter = block
  end

  def make_view
    __static_view_cls__.new @parent, indices
  end

  def clone
    if nrows == 0
      cols = @parent.columns.map{|k, v| [k, NArray.new(v.typecode, 0)]}
    else
      cols = @parent.columns.map{|k, v| [k, v[false, indices]]}
    end
    __table_cls__.new(cols)
  end

  def inspect(*args)
    cache_columns{ super }
  rescue NoMethodError => e
    raise Exception.new(e)
  end

  def indices
    @indices or NArray.int(@parent.nrows).indgen![Util.apply_block(@parent, @filter)]
  end

  def cache_indices
    @indices = indices
    value = yield
    @indices = nil
    value
  end

  def columns
    @columns or super
  end

  def cache_columns
    @columns = columns
    value = yield
    @columns = nil
    value
  end

end
