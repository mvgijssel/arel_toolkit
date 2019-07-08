# typed: true
Arel::InsertManager.class_eval do
  sig { params(other: Arel::InsertManager).returns(T::Boolean) }
  def ==(other)
    @ast == other.ast
  end
end