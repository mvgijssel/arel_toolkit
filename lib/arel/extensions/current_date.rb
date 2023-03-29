# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class CurrentDate < Arel::Nodes::Node
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_CurrentDate(_o, collector)
        collector << 'current_date'
      end
    end

    class Dot
      alias visit_Arel_Nodes_CurrentDate terminal
    end
  end
end

# rubocop:enable Naming/MethodName
