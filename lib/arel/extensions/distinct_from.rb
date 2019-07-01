module Arel
  module Nodes
    class DistinctFrom < Arel::Nodes::InfixOperation
      def initialize(left, right)
        super(:'IS DISTINCT FROM', left, right)
      end
    end
  end
end
