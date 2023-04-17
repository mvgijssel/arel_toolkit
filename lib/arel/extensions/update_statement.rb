# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class UpdateStatement
      module UpdateStatementExtension
        # https://www.postgresql.org/docs/10/sql-update.html
        attr_accessor :with
        attr_accessor :froms, :returning

        def initialize(relation = nil)
          super(relation)

          @froms = []
          @returning = []
        end
      end

      prepend UpdateStatementExtension
    end
  end

  module Visitors
    class ToSql
      # rubocop:disable Metrics/AbcSize
      def visit_Arel_Nodes_UpdateStatement(o, collector)
        if o.with
          collector = visit o.with, collector
          collector << ' '
        end

        wheres = if Gem.loaded_specs['activerecord'].version >= Gem::Version.new('6.0.0')
                   o = prepare_update_statement(o)
                   o.wheres
                 elsif o.orders.empty? && o.limit.nil?
                   o.wheres
                 else
                   [Nodes::In.new(o.key, [build_subselect(o.key, o)])]
                 end

        collector << 'UPDATE '
        collector = visit o.relation, collector

        collect_nodes_for o.values, collector, ' SET '
        collect_nodes_for o.froms, collector, ' FROM ', ', '

        collect_nodes_for wheres, collector, ' WHERE ', ' AND '
        collect_nodes_for o.returning, collector, ' RETURNING ', ', '

        collector
      end
      # rubocop:enable Metrics/AbcSize
    end

    class Dot
      module UpdateStatementExtension
        def visit_Arel_Nodes_UpdateStatement(o)
          super

          visit_edge o, 'with'
          visit_edge o, 'froms'
          visit_edge o, 'returning'
        end
      end

      prepend UpdateStatementExtension
    end
  end
end

# rubocop:enable Naming/MethodName
