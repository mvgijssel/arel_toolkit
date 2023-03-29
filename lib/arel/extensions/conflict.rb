# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class Conflict < Arel::Nodes::Node
      attr_accessor :action, :infer, :values, :wheres
    end
  end

  module Visitors
    class ToSql
      # rubocop:disable Metrics/AbcSize
      def visit_Arel_Nodes_Conflict(o, collector)
        collector << ' ON CONFLICT '

        visit(o.infer, collector) if o.infer

        case o.action
        when :ONCONFLICT_NOTHING
          collector << 'DO NOTHING'
        when :ONCONFLICT_UPDATE
          collector << 'DO UPDATE SET '
        else
          raise "Unknown conflict clause `#{o.action}`"
        end

        o.values.any? && (inject_join o.values, collector, ', ')

        if o.wheres.any?
          collector << ' WHERE '
          collector = inject_join o.wheres, collector, ' AND '
        end

        collector
      end
      # rubocop:enable Metrics/AbcSize
    end

    class Dot
      def visit_Arel_Nodes_Conflict(o)
        visit_edge o, 'action'
        visit_edge o, 'infer'
        visit_edge o, 'values'
        visit_edge o, 'wheres'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
