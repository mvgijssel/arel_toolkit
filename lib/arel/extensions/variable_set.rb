# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.3/sql-set.html
    class VariableSet < Arel::Nodes::Node
      attr_reader :type, :args, :name, :local

      def initialize(type, args, name, local)
        @type = type
        @args = args
        @name = name
        @local = local
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_VariableSet(o, collector)
        collector << 'SET '
        collector << 'LOCAL ' if o.local

        if o.name == 'timezone'
          collector << 'TIME ZONE '
        else
          collector << o.name
          collector << ' TO '
        end

        if o.args.empty?
          collector << 'DEFAULT'
        else
          inject_join(o.args, collector, ', ')
        end
      end
    end

    class Dot
      def visit_Arel_Nodes_VariableSet(o)
        visit_edge o, 'type'
        visit_edge o, 'args'
        visit_edge o, 'name'
        visit_edge o, 'local'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
