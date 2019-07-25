# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName


module Arel
  module Visitors
    class Dot
      def visit_Arel_Nodes_Dealocate(o)
        visit_edge o, 'name'
      end
    end

    class ToSql
      def visit_Arel_Nodes_Dealocate(o, collector)
        collector << 'DEALLOCATE ' << (o.name || 'ALL')
      end
    end
  end

  module Nodes
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
