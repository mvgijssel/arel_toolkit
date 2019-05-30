# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class BitString < Arel::Nodes::Node
      attr_reader :str

      def initialize(str)
        super()

        @str = str
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_BitString(o, collector)
        collector << "B'#{o.str[1..-1]}'"
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
