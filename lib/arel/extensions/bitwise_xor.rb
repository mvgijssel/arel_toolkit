module Arel
  module Nodes
    # https://github.com/mvgijssel/arel_toolkit/issues/45
    class BitwiseXor < InfixOperation
      def initialize(left, right)
        super('#', left, right)
      end
    end
  end
end
