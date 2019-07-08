# typed: true
module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.3/functions-net.html
    class ContainedWithinEquals < Arel::Nodes::InfixOperation
      sig { params(left: Arel::Nodes::TypeCast, right: Arel::Nodes::TypeCast).void }
      def initialize(left, right)
        super(:'<<=', left, right)
      end
    end
  end
end