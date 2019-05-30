module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.1/functions-array.html
    class Overlap < InfixOperation
      def initialize(left, right)
        super(:'&&', left, right)
      end
    end
  end
end
