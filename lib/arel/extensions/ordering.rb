# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class Ordering
      module OrderingExtension
        # Postgres: https://www.postgresql.org/docs/9.4/queries-order.html
        attr_accessor :nulls

        def initialize(expr, nulls = 0)
          super(expr)

          @nulls = nulls
        end
      end

      prepend OrderingExtension
    end
  end

  module Visitors
    class ToSql
      alias old_visit_Arel_Nodes_Ascending visit_Arel_Nodes_Ascending
      def visit_Arel_Nodes_Ascending(o, collector)
        old_visit_Arel_Nodes_Ascending(o, collector)
        apply_ordering_nulls(o, collector)
      end

      alias old_visit_Arel_Nodes_Descending visit_Arel_Nodes_Descending
      def visit_Arel_Nodes_Descending(o, collector)
        old_visit_Arel_Nodes_Descending(o, collector)
        apply_ordering_nulls(o, collector)
      end

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

    class Dot
      module OrderingExtension
        def visit_Arel_Nodes_Ordering(o)
          super
          visit_edge o, 'nulls'
        end
      end

      prepend OrderingExtension
    end
  end
end

# rubocop:enable Naming/MethodName
