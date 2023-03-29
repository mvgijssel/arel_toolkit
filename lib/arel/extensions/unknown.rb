# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class Unknown < Arel::Nodes::Node
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Unknown(_o, collector)
        collector << 'UNKNOWN'
      end
    end

    class Dot
      alias visit_Arel_Nodes_Unknown terminal
    end
  end
end

# rubocop:enable Naming/MethodName
