require 'forwardable'

module ObjectTable::Factory

  CLASS_MAP = {
    '__static_view_cls__' => 'StaticView',
    '__view_cls__'        => 'View',
    '__group_cls__'       => 'Group',
    }.freeze
  FACTORIES = (CLASS_MAP.keys + ['__table_cls__']).freeze

  module ClassMethods

    CLASS_MAP.each do |name, const|
      eval "def #{name}; self::#{const}; end"
    end

    def __table_cls__
      self
    end

    def fully_include(mixin)
      include(mixin)
      constants = constants(false)
      CLASS_MAP.each do |name, const|
        child_cls = send(name)
        # create a new subclass if there isn't already one
        child_cls = const_set(const, Class.new(child_cls)) unless constants.include?(child_cls)
        child_cls.send(:include, mixin)
      end
    end
  end

  extend Forwardable
  def_delegators 'self.class', *FACTORIES

  def self.included(base)
    base.extend(ClassMethods)
  end

  module SubFactory
    FACTORIES.each do |name|
      eval "def #{name}; @#{name} ||= @parent.#{name}; end"
    end
  end

end
