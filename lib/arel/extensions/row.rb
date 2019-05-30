# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.2/sql-expressions.html
    class Row < Arel::Nodes::Unary
      attr_reader :row_format

      def initialize(args, row_format)
        super(args)

        @row_format = row_format
      end
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
# rubocop:enable Naming/UncommunicativeMethodParamName
