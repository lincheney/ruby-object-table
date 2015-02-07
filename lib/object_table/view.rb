require 'forwardable'
require_relative 'view_methods'
require_relative 'masked_column'

class ObjectTable::View
  include ObjectTable::ViewMethods

  extend Forwardable
  def_delegators :make_view, :apply

  def initialize(parent, &block)
    super()
    @parent = parent
    @filter = block
  end

  def_delegators :@parent, :has_column?

  def make_view
    __static_view_cls__.new @parent, indices
  end

  def clone
    __table_cls__.new(columns)
  end

  def inspect(*args)
    cache_columns{ super }
  rescue NoMethodError => e
    raise Exception.new(e)
  end

  def indices
    @indices or NArray.int(@parent.nrows).indgen![@parent._apply_block &@filter]
  end

  def cache_indices(&block)
    @indices = indices
    value = block.call()
    @indices = nil
    value
  end

  def columns
    @columns or super
  end

  def cache_columns(&block)
    @columns = columns
    value = block.call()
    @columns = nil
    value
  end

end
