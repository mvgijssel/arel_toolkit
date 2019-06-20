# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.5/sql-insert.html
    Arel::Nodes::DeleteStatement.class_eval do
      attr_accessor :using
      attr_accessor :with
      attr_accessor :returning

      alias_method :old_initialize, :initialize
      def initialize(relation = nil, wheres = [])
        old_initialize(relation, wheres)

        @returning = []
      end
    end
  end

  module Visitors
    class ToSql
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

        binding.pry

        unless o.returning.empty?
          collector << ' RETURNING '
          collector = inject_join o.returning, collector, ', '
        end

        maybe_visit o.limit, collector
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
