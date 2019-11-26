# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.1/functions-comparison.html
    class BetweenSymmetric < Arel::Nodes::Between; end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_BetweenSymmetric(o, collector)
        collector = visit o.left, collector
        collector << ' BETWEEN SYMMETRIC '
        visit o.right, collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
