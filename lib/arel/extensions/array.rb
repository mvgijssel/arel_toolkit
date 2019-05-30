# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class Array < Arel::Nodes::Node
      attr_reader :items

      def initialize(items)
        super()

        @items = items
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Array(o, collector)
        collector << 'ARRAY['
        inject_join(o.items, collector, ', ')
        collector << ']'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
