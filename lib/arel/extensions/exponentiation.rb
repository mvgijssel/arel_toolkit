# typed: true
module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.1/functions-array.html
    class Exponentiation < InfixOperation
      sig { params(left: Arel::Nodes::SqlLiteral, right: Arel::Nodes::SqlLiteral).void }
      def initialize(left, right)
        super(:^, left, right)
      end
    end
  end
end