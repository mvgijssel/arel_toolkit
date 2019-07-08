# typed: true
module Arel
  module Nodes
    class Least < Arel::Nodes::NamedFunction
      sig { params(args: T::Array[T.any(Integer, Arel::Nodes::UnboundColumnReference, Arel::Nodes::Quoted)]).void }
      def initialize(args)
        super 'LEAST', args
      end
    end
  end
end