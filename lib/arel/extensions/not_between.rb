# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class NotBetween < Arel::Nodes::Between; end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_NotBetween(o, collector)
        collector = visit o.left, collector
        collector << ' NOT BETWEEN '
        visit o.right, collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
