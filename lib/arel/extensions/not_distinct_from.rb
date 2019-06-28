module Arel
  module Nodes
    class NotDistinctFrom < Arel::Nodes::InfixOperation
      def initialize(left, right)
        super(:'IS NOT DISTINCT FROM', left, right)
      end
    end
  end
end
