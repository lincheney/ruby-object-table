require_relative 'view_methods'
require_relative 'basic_grid'
require_relative 'masked_column'

class ObjectTable::StaticView
  include ObjectTable::ViewMethods
  attr_reader :indices

  def initialize(parent, indices)
    super()
    @parent = parent
    @indices = indices
    @columns = ObjectTable::BasicGrid.new
    @fully_cached = false
  end

  def columns
    unless @fully_cached
      @parent.columns.map{|k, v| get_column(k)}
      @fully_cached = true
    end
    @columns
  end

  def get_column(name)
    @columns[name] ||= super
  end

  def add_column(name, *args)
    @columns[name] = super
  end

end
