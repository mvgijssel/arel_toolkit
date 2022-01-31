require_relative './enhance/node'
require_relative './enhance/path'
require_relative './enhance/path_node'
require_relative './enhance/query'
require_relative './enhance/query_methods'
require_relative './enhance/visitor'

module Arel
  module Enhance
  end

  def self.enhance(object, context_enhancers = Arel::Enhance::Visitor::DEFAULT_CONTEXT_ENHANCERS)
    return object if object.is_a?(Arel::Enhance::Node)

    Arel::Enhance::Visitor.new.accept(object, context_enhancers)
  end
end
