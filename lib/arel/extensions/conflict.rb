# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class Conflict < Arel::Nodes::Node
      attr_accessor :action
      attr_accessor :infer
      attr_accessor :values
      attr_accessor :wheres
    end
  end

  module Visitors
    class ToSql
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
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
