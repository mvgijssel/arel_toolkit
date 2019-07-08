# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class CurrentDate < Arel::Nodes::Node
    end
  end

  module Visitors
    class ToSql
      sig { params(_o: Arel::Nodes::CurrentDate, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_CurrentDate(_o, collector)
        collector << 'current_date'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName