require_relative 'static_view'

class ObjectTable::Group < ObjectTable::StaticView
  attr_reader :K

  def initialize(parent, keys, value)
    super(parent, value)
    @K = keys
  end
end
