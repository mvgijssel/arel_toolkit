# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class Operator < Arel::Nodes::Binary
      attr_reader :operator
      def initialize(operator, left, right)
        @operator = operator

        super(left, right)
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Operator(o, collector)
        infix_value o, collector, o.operator
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
