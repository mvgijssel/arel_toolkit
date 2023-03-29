# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class Into < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Into(o, collector)
        collector << 'INTO '
        visit o.expr, collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
