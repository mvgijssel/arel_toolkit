# typed: true
module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-json.html#FUNCTIONS-JSONB-OP-TABLE
    class JsonbAnyKeyExists < Arel::Nodes::InfixOperation
      sig { params(left: Arel::Nodes::TypeCast, right: T.any(Arel::Nodes::Array, Arel::Nodes::TypeCast)).void }
      def initialize(left, right)
        super(:'?|', left, right)
      end
    end
  end
end