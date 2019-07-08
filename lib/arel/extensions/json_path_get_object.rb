# typed: true
module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-json.html#FUNCTIONS-JSON-OP-TABLE
    class JsonPathGetObject < Arel::Nodes::InfixOperation
      sig { params(left: Arel::Nodes::TypeCast, right: Arel::Nodes::Quoted).void }
      def initialize(left, right)
        super(:'#>', left, right)
      end
    end
  end
end