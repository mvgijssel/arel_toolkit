# typed: true
module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-math.html
    class Absolute < Arel::Nodes::UnaryOperation
      sig { params(operand: Integer).void }
      def initialize(operand)
        super('@', operand)
      end
    end
  end
end