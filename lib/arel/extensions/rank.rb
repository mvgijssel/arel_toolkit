# typed: true
module Arel
  module Nodes
    class Rank < Arel::Nodes::NamedFunction
      sig { params(args: T::Array[Arel::Nodes::UnboundColumnReference]).void }
      def initialize(args)
        super 'RANK', args
      end
    end
  end
end