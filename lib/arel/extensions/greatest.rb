# typed: true
module Arel
  module Nodes
    class Greatest < Arel::Nodes::NamedFunction
      sig { params(args: T::Array[T.any(Arel::Nodes::BindParam, Arel::Nodes::TypeCast, Arel::Nodes::SqlLiteral)]).void }
      def initialize(args)
        super 'GREATEST', args
      end
    end
  end
end