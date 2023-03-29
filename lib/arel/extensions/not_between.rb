# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class NotBetween < Arel::Nodes::Between
    end
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
