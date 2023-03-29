# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class NamedArgument < Arel::Nodes::Binary
      alias name left
      alias value right
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
