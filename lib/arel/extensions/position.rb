# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.1/functions-string.html#FUNCTIONS-STRING-SQL
    class Position < Arel::Nodes::Binary
      alias substring left
      alias string right
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Position(o, collector)
        collector << 'position('
        visit o.substring, collector
        collector << ' in '
        visit o.string, collector
        collector << ')'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
