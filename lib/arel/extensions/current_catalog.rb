# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class CurrentCatalog < Arel::Nodes::Node
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_CurrentCatalog(_o, collector)
        collector << 'current_catalog'
      end
    end

    class Dot
      alias visit_Arel_Nodes_CurrentCatalog terminal
    end
  end
end

# rubocop:enable Naming/MethodName
