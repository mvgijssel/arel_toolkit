# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName


module Arel
  module Visitors
    class Dot
      def visit_Arel_Nodes_Prepare(o)
        visit_edge o, 'name'
        visit_edge o, 'argtypes'
        visit_edge o, 'query'
      end
    end

    class ToSql
      def visit_Arel_Nodes_Prepare(o, collector)
        collector << "PREPARE #{o.name}"
        collector << " (#{o.argtypes.join(', ')})" if o.argtypes
        collector << " AS ("
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
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
