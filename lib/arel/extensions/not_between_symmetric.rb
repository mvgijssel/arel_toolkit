# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.1/functions-comparison.html
    class NotBetweenSymmetric < Arel::Nodes::BetweenSymmetric
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::NotBetweenSymmetric, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_NotBetweenSymmetric(o, collector)
        collector = visit o.left, collector
        collector << ' NOT BETWEEN SYMMETRIC '
        visit o.right, collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName