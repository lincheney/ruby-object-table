module ObjectTable::TableChild

  def __static_view_cls__
    @__static_view_cls__ ||= @parent.__static_view_cls__
  end

  def __view_cls__
    @__view_cls__ ||= @parent.__view_cls__
  end

  def __group_cls__
    @__group_cls__ ||= @parent.__group_cls__
  end

  def __table_cls__
    @__table_cls__ ||= @parent.__table_cls__
  end

end