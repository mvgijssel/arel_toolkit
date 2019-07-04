require_relative './transformer/node'
require_relative './transformer/visitor'

module Arel
  module Transformer
  end

  def self.transformer(arel)
    Arel::Transformer::Visitor.new.accept(arel)
  end
end
