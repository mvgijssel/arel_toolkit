# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.1/functions-comparisons.html
    class ArraySubselect < Arel::Nodes::Unary; end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_ArraySubselect(o, collector)
        collector << 'ARRAY('
        visit o.expr, collector
        collector << ')'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
