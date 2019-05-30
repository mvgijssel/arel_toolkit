module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-math.html
    class SquareRoot < Arel::Nodes::UnaryOperation
      def initialize(operand)
        super('|/', operand)
      end
    end
  end
end
