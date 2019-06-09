Arel::UpdateManager.class_eval do
  def ==(other)
    @ast == other.ast && @ctx == other.ctx
  end

  protected

  attr_reader :ctx
end
