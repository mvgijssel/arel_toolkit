# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.2/functions-datetime.html#FUNCTIONS-DATETIME-ZONECONVERT
    class AtTimeZone < Arel::Nodes::Unary
      attr_reader :timezone

      sig { params(expr: T.any(Arel::Nodes::TypeCast, T::Array[Arel::Nodes::AtTimeZone], Arel::Nodes::Grouping), timezone: Arel::Nodes::Quoted).void }
      def initialize(expr, timezone)
        super(expr)

        @timezone = timezone
      end
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::AtTimeZone, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_AtTimeZone(o, collector)
        visit o.expr, collector
        collector << ' AT TIME ZONE '
        visit o.timezone, collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName