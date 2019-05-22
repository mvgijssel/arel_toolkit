require 'arel'
require 'arel_extensions'

module Arel
  module Nodes
    class Unknown < Arel::Nodes::Node
    end

    class CurrentDate < Arel::Nodes::Node
    end

    class CurrentTimestamp < Arel::Nodes::Node
    end

    class CurrentTime < Arel::Nodes::Node
      attr_reader :precision

      def initialize(precision: nil)
        super()

        @precision = precision
      end
    end
  end

  module Visitors
    class ToSql
      private

      def visit_Arel_Nodes_CurrentTime(o, collector)
        collector << 'current_time'
        collector << "(#{o.precision.to_i})" if o.precision
      end

      def visit_Arel_Nodes_CurrentDate(o, collector)
        collector << 'current_date'
      end

      def visit_Arel_Nodes_CurrentTimestamp(o, collector)
        collector << 'current_timestamp'
      end

      def visit_Arel_Nodes_NotEqual(o, collector)
        right = o.right

        collector = visit o.left, collector

        case right
        when Arel::Nodes::Unknown, Arel::Nodes::False, Arel::Nodes::True
          collector << ' IS NOT '
          visit right, collector

        when NilClass
          collector << ' IS NOT NULL'

        else
          collector << ' != '
          visit right, collector
        end
      end

      def visit_Arel_Nodes_Equality(o, collector)
        right = o.right

        collector = visit o.left, collector

        case right
        when Arel::Nodes::Unknown, Arel::Nodes::False, Arel::Nodes::True
          collector << ' IS '
          visit right, collector

        when NilClass
          collector << ' IS NULL'

        else
          collector << ' = '
          visit right, collector
        end
      end

      def visit_Arel_Nodes_Unknown(_o, collector)
        collector << 'UNKNOWN'
      end
    end
  end
end
