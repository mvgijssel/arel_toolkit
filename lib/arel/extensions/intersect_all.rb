# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class IntersectAll < Binary; end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_IntersectAll(o, collector)
        collector << '( '
        infix_value(o, collector, ' INTERSECT ALL ') << ' )'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
