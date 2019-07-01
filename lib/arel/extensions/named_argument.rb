# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class NamedArgument < Arel::Nodes::Node
      attr_reader :name
      attr_reader :value

      def initialize(name, value)
        @name = name
        @value = value
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_NamedArgument(o, collector)
        collector << o.name
        collector << ' => '
        visit(o.value, collector)
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
