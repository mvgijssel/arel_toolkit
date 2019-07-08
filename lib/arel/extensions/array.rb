# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class Array < Arel::Nodes::Node
      attr_reader :items

      sig { params(items: T::Array[T.any(Integer, Arel::Nodes::SqlLiteral)]).void }
      def initialize(items)
        super()

        @items = items
      end
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::Array, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
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