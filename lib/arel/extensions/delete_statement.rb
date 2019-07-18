# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class DeleteStatement
      module DeleteStatementExtension
        attr_accessor :using
        attr_accessor :with
        attr_accessor :returning

        def initialize(relation = nil, wheres = [])
          super

          @returning = []
        end
      end

      prepend DeleteStatementExtension
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

        unless o.returning.empty?
          collector << ' RETURNING '
          collector = inject_join o.returning, collector, ', '
        end

        maybe_visit o.limit, collector
      end
      # rubocop:enable Metrics/AbcSize
    end

    class Dot
      module DeleteStatementExtension
        def visit_Arel_Nodes_DeleteStatement(o)
          super

          visit_edge o, 'using'
          visit_edge o, 'with'
          visit_edge o, 'returning'
        end
      end

      prepend(DeleteStatementExtension)
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
