# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class SetToDefault < Arel::Nodes::Node
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_SetToDefault(_o, collector)
        collector << 'DEFAULT'
      end
    end

    class Dot
      alias visit_Arel_Nodes_SetToDefault terminal
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
