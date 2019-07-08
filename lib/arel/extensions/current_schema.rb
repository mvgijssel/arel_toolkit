# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class CurrentSchema < Arel::Nodes::Node
    end
  end

  module Visitors
    class ToSql
      sig { params(_o: Arel::Nodes::CurrentSchema, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_CurrentSchema(_o, collector)
        collector << 'current_schema'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName