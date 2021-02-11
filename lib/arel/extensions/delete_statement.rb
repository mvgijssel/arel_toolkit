# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/10/sql-delete.html
    class DeleteStatement
      module DeleteStatementExtension
        attr_accessor :using
        attr_accessor :with
        attr_accessor :returning
        attr_accessor :orders

        def initialize(relation = nil, wheres = [])
          super

          @returning = []
          @orders = []
          @using = []
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
          collector << ' '
        end

        if Gem.loaded_specs['activerecord'].version >= Gem::Version.new('6.0.0')
          o = prepare_delete_statement(o)

          if has_join_sources?(o)
            collector << 'DELETE '
            visit o.relation.left, collector
            collector << ' FROM '
          else
            collector << 'DELETE FROM '
          end
        else
          collector << 'DELETE FROM '
        end

        collector = visit o.relation, collector

        collect_nodes_for o.using, collector, ' USING ', ', '
        collect_nodes_for o.wheres, collector, ' WHERE ', ' AND '
        collect_nodes_for o.returning, collector, ' RETURNING ', ', '
        collect_nodes_for o.orders, collector, ' ORDER BY '
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
