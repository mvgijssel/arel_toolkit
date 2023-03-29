# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class CurrentSchema < Arel::Nodes::Node
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_CurrentSchema(_o, collector)
        collector << 'current_schema'
      end
    end

    class Dot
      alias visit_Arel_Nodes_CurrentSchema terminal
    end
  end
end

# rubocop:enable Naming/MethodName
