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

      def visit_Arel_Nodes_CurrentRole(_o, collector)
        collector << 'current_role'
      end

      def visit_Arel_Nodes_CurrentUser(_o, collector)
        collector << 'current_user'
      end

      def visit_Arel_Nodes_SessionUser(_o, collector)
        collector << 'session_user'
      end

      def visit_Arel_Nodes_User(_o, collector)
        collector << 'user'
      end

      def visit_Arel_Nodes_CurrentCatalog(_o, collector)
        collector << 'current_catalog'
      end

      def visit_Arel_Nodes_CurrentSchema(_o, collector)
        collector << 'current_schema'
      end

      def visit_Arel_Nodes_Array(o, collector)
        collector << 'ARRAY['
        inject_join(o.items, collector, ', ')
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

      def visit_Arel_Nodes_NaturalJoin(o, collector)
        collector << 'NATURAL JOIN '
        visit o.left, collector
      end

      def visit_Arel_Nodes_CrossJoin(o, collector)
        collector << 'CROSS JOIN '
        visit o.left, collector
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
      def visit_Arel_Nodes_Ascending(o, collector)
        old_visit_Arel_Nodes_Ascending(o, collector)
        apply_ordering_nulls(o, collector)
      end

      alias old_visit_Arel_Nodes_Descending visit_Arel_Nodes_Descending
      def visit_Arel_Nodes_Descending(o, collector)
        old_visit_Arel_Nodes_Descending(o, collector)
        apply_ordering_nulls(o, collector)
      end

      def visit_Arel_Nodes_All(o, collector)
        collector << 'ALL('
        visit o.expr, collector
        collector << ')'
      end

      def visit_Arel_Nodes_Any(o, collector)
        collector << 'ANY('
        visit o.expr, collector
        collector << ')'
      end

      def visit_Arel_Nodes_ArraySubselect(o, collector)
        collector << 'ARRAY('
        visit o.expr, collector
        collector << ')'
      end

      def visit_Arel_Nodes_TypeCast(o, collector)
        visit o.arg, collector
        collector << '::'
        collector << o.type_name
      end

      def visit_Arel_Nodes_DistinctFrom(o, collector)
        visit o.left, collector
        collector << ' IS DISTINCT FROM '
        visit o.right, collector
      end

      def visit_Arel_Nodes_NotDistinctFrom(o, collector)
        visit o.left, collector
        collector << ' IS NOT DISTINCT FROM '
        visit o.right, collector
      end

      def visit_Arel_Nodes_NullIf(o, collector)
        collector << 'NULLIF('
        visit o.left, collector
        collector << ', '
        visit o.right, collector
        collector << ')'
      end

      def visit_Arel_Nodes_Similar(o, collector)
        visit o.left, collector
        collector << ' SIMILAR TO '
        visit o.right, collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_Arel_Nodes_NotSimilar(o, collector)
        visit o.left, collector
        collector << ' NOT SIMILAR TO '
        visit o.right, collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end

      def visit_Arel_Nodes_NotBetween(o, collector)
        collector = visit o.left, collector
        collector << ' NOT BETWEEN '
        visit o.right, collector
      end

      def visit_Arel_Nodes_BetweenSymmetric(o, collector)
        collector = visit o.left, collector
        collector << ' BETWEEN SYMMETRIC '
        visit o.right, collector
      end

      def visit_Arel_Nodes_NotBetweenSymmetric(o, collector)
        collector = visit o.left, collector
        collector << ' NOT BETWEEN SYMMETRIC '
        visit o.right, collector
      end

      def visit_Arel_Nodes_NamedFunction(o, collector)
        aggregate(o.name, o, collector)
      end

      def visit_Arel_Nodes_Factorial(o, collector)
        if o.prefix
          collector << '!! '
          visit o.expr, collector
        else
          visit o.expr, collector
          collector << ' !'
        end
      end

      def visit_Arel_Nodes_DefaultValues(_o, collector)
        collector << 'DEFAULT VALUES'
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/PerceivedComplexity
      def visit_Arel_Nodes_InsertStatement(o, collector)
        if o.with
          collector = visit o.with, collector
          collector << SPACE
        end

        collector << 'INSERT INTO '
        collector = visit o.relation, collector
        if o.columns.any?
          collector << " (#{o.columns.map do |x|
            quote_column_name x.name
          end.join ', '})"
        end

        case o.override
        when 0
          collector << ''
        when 1
          collector << ' OVERRIDING USER VALUE'
        when 2
          collector << ' OVERRIDING SYSTEM VALUE'
        else
          raise "Unknown override `#{o.override}`"
        end

        collector = if o.values
                      maybe_visit o.values, collector
                    elsif o.select
                      maybe_visit o.select, collector
                    else
                      collector
                    end

        unless o.returning.empty?
          collector << ' RETURNING '
          collector = inject_join o.returning, collector, ', '
        end

        visit(o.on_conflict, collector) if o.on_conflict
        collector
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/PerceivedComplexity

      # rubocop:disable Metrics/AbcSize
      def visit_Arel_Nodes_Conflict(o, collector)
        collector << ' ON CONFLICT '

        visit(o.infer, collector) if o.infer

        case o.action
        when 1
          collector << 'DO NOTHING'
        when 2
          collector << 'DO UPDATE SET '
        else
          raise "Unknown conflict clause `#{action}`"
        end

        o.values.any? && (inject_join o.values, collector, ', ')

        if o.wheres.any?
          collector << ' WHERE '
          collector = inject_join o.wheres, collector, ' AND '
        end

        collector
      end
      # rubocop:enable Metrics/AbcSize

      def visit_Arel_Nodes_Infer(o, collector)
        if o.name
          collector << 'ON CONSTRAINT '
          collector << o.name
          collector << SPACE
        end

        if o.indexes
          collector << '('
          inject_join o.indexes, collector, ', '
          collector << ') '
        end

        collector
      end

      def visit_Arel_Nodes_SetToDefault(_o, collector)
        collector << 'DEFAULT'
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/PerceivedComplexity
      def visit_Arel_Nodes_UpdateStatement(o, collector)
        if o.with
          collector = visit o.with, collector
          collector << SPACE
        end

        wheres = if o.orders.empty? && o.limit.nil?
                   o.wheres
                 else
                   [Nodes::In.new(o.key, [build_subselect(o.key, o)])]
                 end

        collector << 'UPDATE '
        collector = visit o.relation, collector
        unless o.values.empty?
          collector << ' SET '
          collector = inject_join o.values, collector, ', '
        end

        unless o.froms.empty?
          collector << ' FROM '
          collector = inject_join o.froms, collector, ', '
        end

        unless wheres.empty?
          collector << ' WHERE '
          collector = inject_join wheres, collector, ' AND '
        end

        unless o.returning.empty?
          collector << ' RETURNING '
          collector = inject_join o.returning, collector, ', '
        end

        collector
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def visit_Arel_Nodes_CurrentOfExpression(o, collector)
        collector << 'CURRENT OF '
        collector << o.cursor_name
      end

      # rubocop:disable Metrics/AbcSize
      def visit_Arel_Nodes_DeleteStatement(o, collector)
        if o.with
          collector = visit o.with, collector
          collector << SPACE
        end

        collector << 'DELETE FROM '
        collector = visit o.relation, collector

        if o.using
          collector << ' USING '
          collector = inject_join o.using, collector, ', '
        end

        if o.wheres.any?
          collector << WHERE
          collector = inject_join o.wheres, collector, AND
        end

        unless o.returning.empty?
          collector << ' RETURNING '
          collector = inject_join o.returning, collector, ', '
        end

        maybe_visit o.limit, collector
      end
      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      def aggregate(name, o, collector)
        collector << "#{name}("
        collector << 'DISTINCT ' if o.distinct
        collector << 'VARIADIC ' if o.variardic

        collector = inject_join(o.expressions, collector, ', ')

        if o.within_group
          collector << ')'
          collector << ' WITHIN GROUP ('
        end

        if o.orders.any?
          collector << SPACE unless o.within_group
          collector << 'ORDER BY '
          collector = inject_join o.orders, collector, ', '
        end

        collector << ')'

        if o.filter
          collector << ' FILTER(WHERE '
          visit o.filter, collector
          collector << ')'
        end

        if o.alias
          collector << ' AS '
          visit o.alias, collector
        else
          collector
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize

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
