# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.1/sql-expressions.html
    class TypeCast < Arel::Nodes::Node
      attr_reader :arg
      attr_reader :type_name

      def initialize(arg, type_name)
        @arg = arg
        @type_name = type_name
      end

      def ==(other)
        self.class == other.class && arg == other.arg && type_name == other.type_name
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_TypeCast(o, collector)
        visit o.arg, collector
        collector << '::'
        collector << o.type_name
      end
    end

    class Dot
      def visit_Arel_Nodes_TypeCast(o)
        visit_edge(o, 'arg')
        visit_edge(o, 'type_name')
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
