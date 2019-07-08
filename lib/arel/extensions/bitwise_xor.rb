# typed: true
module Arel
  module Nodes
    # https://github.com/mvgijssel/arel_toolkit/issues/45
    class BitwiseXor < InfixOperation
      sig { params(left: T.any(Integer, Arel::Nodes::TypeCast), right: T.any(Integer, Arel::Nodes::TypeCast)).void }
      def initialize(left, right)
        super('#', left, right)
      end
    end
  end
end