# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class Indirection < Arel::Nodes::Binary; end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Indirection(o, collector)
        visit(o.left, collector)
        collector << '['
        visit(o.right, collector)
        collector << ']'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
