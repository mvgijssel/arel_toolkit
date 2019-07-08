# typed: true
Arel::SelectManager.class_eval do
  sig { params(other: Arel::SelectManager).returns(T::Boolean) }
  def ==(other)
    @ast == other.ast && @ctx == other.ctx
  end

  protected

  attr_reader :ctx
end