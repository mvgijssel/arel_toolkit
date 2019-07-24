# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Visitors
    class Dot
      alias visit_Arel_Nodes_Dealocate terminal
      alias visit_Arel_Nodes_Prepare terminal
    end

    class ToSql
      def visit_Arel_Nodes_Dealocate(o, collector)
        collector << 'DEALLOCATE ' << o.name
      end

      def visit_Arel_Nodes_Prepare(o, collector)
        collector << "PREPARE #{o.name} (#{o.argtypes.join(', ')}) AS ("
        visit(o.query, collector)
        collector << ')'
      end
    end
  end

  module Nodes
    class Prepare < Node
      attr_reader :name, :query, :argtypes

      def initialize(name, argtypes, query)
        @name = name
        @query = query
        @argtypes = argtypes
      end
    end

    class Dealocate < Node
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
