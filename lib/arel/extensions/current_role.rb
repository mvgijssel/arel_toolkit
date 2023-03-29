# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class CurrentRole < Arel::Nodes::Node
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_CurrentRole(_o, collector)
        collector << 'current_role'
      end
    end

    class Dot
      alias visit_Arel_Nodes_CurrentRole terminal
    end
  end
end

# rubocop:enable Naming/MethodName
