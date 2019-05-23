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

      def visit_Arel_Nodes_NaturalJoin(o, collector)
        collector << "NATURAL JOIN "
        collector = visit o.left, collector
      end

      def visit_Arel_Nodes_CrossJoin(o, collector)
        collector << "CROSS JOIN "
        collector = visit o.left, collector
      end

      # TODO: currently in Arel master, remove in time
      def visit_Arel_Nodes_Lateral(o, collector)
        collector << "LATERAL "
        grouping_parentheses o, collector
      end

      def visit_Arel_Nodes_RangeFunction(o, collector)
        collector << "ROWS FROM ("
        visit o.expr, collector
        collector << ")"
      end

      def visit_Arel_Nodes_WithOrdinality(o, collector)
        visit o.expr, collector
        collector << " WITH ORDINALITY"
      end

      alias_method :old_visit_Arel_Table, :visit_Arel_Table
      def visit_Arel_Table o, collector
        if o.only
          collector << 'ONLY '
        end

        if o.schema_name
          collector << "\"#{o.schema_name}\"."
        end

        old_visit_Arel_Table(o, collector)
      end

      def visit_Arel_Nodes_Row o, collector
        collector << 'ROW('
        visit o.expr, collector
        collector << ')'
      end

      # TODO: currently in Arel master, remove in time
      # Used by Lateral visitor to enclose select queries in parentheses
      def grouping_parentheses(o, collector)
        if o.expr.is_a? Nodes::SelectStatement
          collector << "("
          visit o.expr, collector
          collector << ")"
        else
          visit o.expr, collector
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
