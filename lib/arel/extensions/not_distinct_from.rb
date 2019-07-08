# typed: true
module Arel
  module Nodes
    class NotDistinctFrom < Arel::Nodes::InfixOperation
      sig { params(left: Integer, right: Arel::Nodes::Quoted).void }
      def initialize(left, right)
        super(:'IS NOT DISTINCT FROM', left, right)
      end
    end
  end
end