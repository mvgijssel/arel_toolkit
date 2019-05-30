# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # TODO: currently in Arel master, remove in time
    class Lateral < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql
      # TODO: currently in Arel master, remove in time
      def visit_Arel_Nodes_Lateral(o, collector)
        collector << 'LATERAL '
        grouping_parentheses o, collector
      end

      # TODO: currently in Arel master, remove in time
      # Used by Lateral visitor to enclose select queries in parentheses
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
# rubocop:enable Naming/UncommunicativeMethodParamName
