# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.3/functions-net.html
    class ContainsEquals < Arel::Nodes::Binary
      def operator
        :'>>='
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_ContainsEquals(o, collector)
        infix_value o, collector, ' >>= '
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
