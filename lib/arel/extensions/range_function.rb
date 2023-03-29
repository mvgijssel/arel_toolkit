# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.4/sql-select.html
    class RangeFunction < Arel::Nodes::Unary
      attr_reader :is_rowsfrom

      def initialize(*args, is_rowsfrom:, **kwargs)
        @is_rowsfrom = is_rowsfrom
        super(*args, **kwargs)
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_RangeFunction(o, collector)
        collector << 'ROWS FROM (' if o.is_rowsfrom
        visit o.expr, collector
        collector << ')' if o.is_rowsfrom

        collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
