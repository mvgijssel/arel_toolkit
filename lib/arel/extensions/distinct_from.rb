# typed: true
module Arel
  module Nodes
    class DistinctFrom < Arel::Nodes::InfixOperation
      sig { params(left: Arel::Nodes::UnboundColumnReference, right: Arel::Nodes::UnboundColumnReference).void }
      def initialize(left, right)
        super(:'IS DISTINCT FROM', left, right)
      end
    end
  end
end