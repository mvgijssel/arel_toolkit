# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class SessionUser < Arel::Nodes::Node
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_SessionUser(_o, collector)
        collector << 'session_user'
      end
    end

    class Dot
      alias visit_Arel_Nodes_SessionUser terminal
    end
  end
end

# rubocop:enable Naming/MethodName
