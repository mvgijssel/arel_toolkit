# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class DefaultValues < Arel::Nodes::Node
    end
  end

  module Visitors
    class ToSql
      sig { params(_o: Arel::Nodes::DefaultValues, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_DefaultValues(_o, collector)
        collector << 'DEFAULT VALUES'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName