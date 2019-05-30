# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.4/sql-select.html
    class RangeFunction < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_RangeFunction(o, collector)
        collector << 'ROWS FROM ('
        visit o.expr, collector
        collector << ')'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
