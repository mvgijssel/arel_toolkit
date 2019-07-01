module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.3/functions-net.html
    class ContainedWithinEquals < Arel::Nodes::InfixOperation
      def initialize(left, right)
        super(:'<<=', left, right)
      end
    end
  end
end
