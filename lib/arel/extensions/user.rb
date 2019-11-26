# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class User < Arel::Nodes::Node; end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_User(_o, collector)
        collector << 'user'
      end
    end

    class Dot
      alias visit_Arel_Nodes_User terminal
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
