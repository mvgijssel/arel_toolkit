# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.2/functions-datetime.html#FUNCTIONS-DATETIME-ZONECONVERT
    class AtTimeZone < Arel::Nodes::Unary
      attr_reader :timezone

      def initialize(expr, timezone)
        super(expr)

        @timezone = timezone
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_AtTimeZone(o, collector)
        visit o.expr, collector
        collector << ' AT TIME ZONE '
        collector << o.timezone
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
