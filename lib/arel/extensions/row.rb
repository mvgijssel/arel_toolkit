# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.2/sql-expressions.html
    class Row < Arel::Nodes::Binary
      alias expr left
      alias row_format right
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Row(o, collector)
        collector << 'ROW('
        visit o.expr, collector
        collector << ')'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
