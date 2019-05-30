module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-math.html
    class Modulo < Arel::Nodes::InfixOperation
      def initialize(left, right)
        super(:%, left, right)
      end
    end
  end
end
