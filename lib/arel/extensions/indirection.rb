# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class Indirection < Arel::Nodes::Node
      attr_reader :arg
      attr_reader :indirection

      sig { params(arg: Arel::Nodes::UnboundColumnReference, indirection: T::Array[Integer]).void }
      def initialize(arg, indirection)
        super()

        @arg = arg
        @indirection = indirection
      end
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::Indirection, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_Indirection(o, collector)
        visit(o.arg, collector)
        collector << '['
        visit(o.indirection, collector)
        collector << ']'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName