# typed: true
Arel::DeleteManager.class_eval do
  sig { params(other: Arel::DeleteManager).returns(T::Boolean) }
  def ==(other)
    @ast == other.ast && @ctx == other.ctx
  end

  protected

  attr_reader :ctx
end