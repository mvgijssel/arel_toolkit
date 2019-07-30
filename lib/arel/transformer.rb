require_relative './transformer/node'
require_relative './transformer/path'
require_relative './transformer/path_node'
require_relative './transformer/query'
require_relative './transformer/visitor'

require_relative './transformer/add_schema_to_table'

module Arel
  module Transformer
  end

  def self.transformer(object)
    return object if object.is_a?(Arel::Transformer::Node)

    Arel::Transformer::Visitor.new.accept(object)
  end
end
