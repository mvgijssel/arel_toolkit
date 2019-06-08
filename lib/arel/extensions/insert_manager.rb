Arel::InsertManager.class_eval do
  def ==(other)
    @ast == other.ast
  end
end
