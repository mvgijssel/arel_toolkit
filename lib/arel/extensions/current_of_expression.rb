# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/10/sql-update.html
    class CurrentOfExpression < Arel::Nodes::Node
      attr_accessor :cursor_name

      def initialize(cursor_name)
        super()

        @cursor_name = cursor_name
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_CurrentOfExpression(o, collector)
        collector << 'CURRENT OF '
        collector << o.cursor_name
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
