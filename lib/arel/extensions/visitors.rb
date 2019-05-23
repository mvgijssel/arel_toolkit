# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Visitors
    class ToSql
      private

      def visit_Arel_Nodes_CurrentTime(o, collector)
        collector << 'current_time'
        collector << "(#{o.precision.to_i})" if o.precision
        collector
      end

      def visit_Arel_Nodes_CurrentDate(_o, collector)
        collector << 'current_date'
      end

      def visit_Arel_Nodes_CurrentTimestamp(o, collector)
        collector << 'current_timestamp'
        collector << "(#{o.precision.to_i})" if o.precision
        collector
      end

      def visit_Arel_Nodes_LocalTime(o, collector)
        collector << 'localtime'
        collector << "(#{o.precision.to_i})" if o.precision
        collector
      end

      def visit_Arel_Nodes_LocalTimeStamp(o, collector)
        collector << 'localtimestamp'
        collector << "(#{o.precision.to_i})" if o.precision
        collector
      end

      def visit_Arel_Nodes_CurrentRole(o, collector)
        collector << 'current_role'
      end

      def visit_Arel_Nodes_CurrentUser(o, collector)
        collector << 'current_user'
      end

      def visit_Arel_Nodes_SessionUser(o, collector)
        collector << 'session_user'
      end

      def visit_Arel_Nodes_User(o, collector)
        collector << 'user'
      end

      def visit_Arel_Nodes_CurrentCatalog(o, collector)
        collector << 'current_catalog'
      end

      def visit_Arel_Nodes_CurrentSchema(o, collector)
        collector << 'current_schema'
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
        collector << 'NATURAL JOIN '
        collector = visit o.left, collector
      end

      def visit_Arel_Nodes_CrossJoin(o, collector)
        collector << 'CROSS JOIN '
        collector = visit o.left, collector
      end

      # TODO: currently in Arel master, remove in time
      def visit_Arel_Nodes_Lateral(o, collector)
        collector << 'LATERAL '
        grouping_parentheses o, collector
      end

      def visit_Arel_Nodes_RangeFunction(o, collector)
        collector << 'ROWS FROM ('
        visit o.expr, collector
        collector << ')'
      end

      def visit_Arel_Nodes_WithOrdinality(o, collector)
        visit o.expr, collector
        collector << ' WITH ORDINALITY'
      end

      alias old_visit_Arel_Table visit_Arel_Table
      def visit_Arel_Table(o, collector)
        collector << 'ONLY ' if o.only

        collector << "\"#{o.schema_name}\"." if o.schema_name

        old_visit_Arel_Table(o, collector)
      end

      def visit_Arel_Nodes_Row(o, collector)
        collector << 'ROW('
        visit o.expr, collector
        collector << ')'
      end

      alias old_visit_Arel_Nodes_Ascending visit_Arel_Nodes_Ascending
      def visit_Arel_Nodes_Ascending o, collector
        old_visit_Arel_Nodes_Ascending(o, collector)
        apply_ordering_nulls(o, collector)
      end

      alias old_visit_Arel_Nodes_Descending visit_Arel_Nodes_Descending
      def visit_Arel_Nodes_Descending o, collector
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

      # TODO: currently in Arel master, remove in time
      # Used by Lateral visitor to enclose select queries in parentheses
      def grouping_parentheses(o, collector)
        if o.expr.is_a? Nodes::SelectStatement
          collector << '('
          visit o.expr, collector
          collector << ')'
        else
          visit o.expr, collector
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
