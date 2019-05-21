# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Visitors
    class ToSql
      private

      def visit_Arel_Nodes_CurrentTime(o, collector)
        collector << 'current_time'
        collector << "(#{o.precision.to_i})" if o.precision
      end

      def visit_Arel_Nodes_CurrentDate(_o, collector)
        collector << 'current_date'
      end

      def visit_Arel_Nodes_CurrentTimestamp(_o, collector)
        collector << 'current_timestamp'
      end

      def visit_Arel_Nodes_Array(o, collector)
        collector << 'ARRAY['
        o.items.each { |item| visit(item, collector) }
        collector << ']'
      end

      def visit_Arel_Nodes_Indirection(o, collector)
        visit(o.arg, collector)
        collector << '['
        visit(o.indirection, collector)
        collector << ']'
      end

      def visit_Arel_Nodes_BitString(o, collector)
        collector << "B'#{o.str[1..-1]}'"
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

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
