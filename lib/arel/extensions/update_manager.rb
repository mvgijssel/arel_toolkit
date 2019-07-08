# typed: true
Arel::UpdateManager.class_eval do
  sig { params(other: Arel::UpdateManager).returns(T::Boolean) }
  def ==(other)
    @ast == other.ast && @ctx == other.ctx
  end

  protected

  attr_reader :ctx
end