# typed: true
module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-json.html#FUNCTIONS-JSONB-OP-TABLE
    class JsonbAllKeyExists < Arel::Nodes::InfixOperation
      sig { params(left: Arel::Nodes::TypeCast, right: Arel::Nodes::Array).void }
      def initialize(left, right)
        super(:'?&', left, right)
      end
    end
  end
end