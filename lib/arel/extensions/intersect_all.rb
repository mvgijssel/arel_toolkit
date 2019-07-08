# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class IntersectAll < Binary
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::IntersectAll, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_IntersectAll(o, collector)
        collector << '( '
        infix_value(o, collector, ' INTERSECT ALL ') << ' )'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName