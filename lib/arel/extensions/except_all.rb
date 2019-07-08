# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class ExceptAll < Binary
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::ExceptAll, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_ExceptAll(o, collector)
        collector << '( '
        infix_value(o, collector, ' EXCEPT ALL ') << ' )'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName