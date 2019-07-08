# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    Arel::Nodes::Ordering.class_eval do
      # Postgres: https://www.postgresql.org/docs/9.4/queries-order.html
      attr_accessor :nulls

      sig { params(expr: T.any(Arel::Nodes::UnboundColumnReference, Integer, Arel::Nodes::Quoted), nulls: Integer).void }
      def initialize(expr, nulls = 0)
        super(expr)

        @nulls = nulls
      end
    end
  end

  module Visitors
    class ToSql
      alias old_visit_Arel_Nodes_Ascending visit_Arel_Nodes_Ascending
      sig { params(o: Arel::Nodes::Ascending, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_Ascending(o, collector)
        old_visit_Arel_Nodes_Ascending(o, collector)
        apply_ordering_nulls(o, collector)
      end

      alias old_visit_Arel_Nodes_Descending visit_Arel_Nodes_Descending
      sig { params(o: Arel::Nodes::Descending, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_Descending(o, collector)
        old_visit_Arel_Nodes_Descending(o, collector)
        apply_ordering_nulls(o, collector)
      end

      sig { params(o: T.any(Arel::Nodes::Descending, Arel::Nodes::Ascending), collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def apply_ordering_nulls(o, collector)
        case o.nulls
        when 1
          collector << ' NULLS FIRST'
        when 2
          collector << ' NULLS LAST'
        else
          collector
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName