# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/8.1/sql-select.html
    class All < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_All(o, collector)
        collector << 'ALL('
        visit o.expr, collector
        collector << ')'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
