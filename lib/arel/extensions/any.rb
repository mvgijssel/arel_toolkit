# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.1/functions-comparisons.html
    class Any < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Any(o, collector)
        collector << 'ANY('
        visit o.expr, collector
        collector << ')'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
