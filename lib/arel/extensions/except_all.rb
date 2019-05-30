# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class ExceptAll < Binary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_ExceptAll(o, collector)
        collector << '( '
        infix_value(o, collector, ' EXCEPT ALL ') << ' )'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
