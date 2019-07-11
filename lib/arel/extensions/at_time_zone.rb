# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.2/functions-datetime.html#FUNCTIONS-DATETIME-ZONECONVERT
    class AtTimeZone < Arel::Nodes::Node
      attr_reader :timezone
      attr_reader :expr

      def initialize(expr, timezone)
        @expr = expr
        @timezone = timezone
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_AtTimeZone(o, collector)
        visit o.expr, collector
        collector << ' AT TIME ZONE '
        visit o.timezone, collector
      end
    end

    class Dot
      def visit_Arel_Nodes_AtTimeZone(o)
        visit_edge o, 'expr'
        visit_edge o, 'timezone'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
