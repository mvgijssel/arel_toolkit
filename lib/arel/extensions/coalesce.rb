# typed: true
module Arel
  module Nodes
    class Coalesce < Arel::Nodes::NamedFunction
      sig { params(args: T::Array[T.any(Arel::Nodes::UnboundColumnReference, Arel::Nodes::SqlLiteral, Integer, Arel::Nodes::Quoted)]).void }
      def initialize(args)
        super 'COALESCE', args
      end
    end
  end
end