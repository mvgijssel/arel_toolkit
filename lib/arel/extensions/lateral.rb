# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # https://github.com/mvgijssel/arel_toolkit/issues/46
    class Lateral < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql
      # https://github.com/mvgijssel/arel_toolkit/issues/46
      def visit_Arel_Nodes_Lateral(o, collector)
        collector << 'LATERAL '
        grouping_parentheses o, collector
      end

      # https://github.com/mvgijssel/arel_toolkit/issues/46
      def grouping_parentheses(o, collector)
        if o.expr.is_a? Nodes::SelectStatement
          collector << '('
          visit o.expr, collector
          collector << ')'
        else
          visit o.expr, collector
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
