# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.1/functions-comparison.html
    class NotBetweenSymmetric < Arel::Nodes::BetweenSymmetric
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_NotBetweenSymmetric(o, collector)
        collector = visit o.left, collector
        collector << ' NOT BETWEEN SYMMETRIC '
        visit o.right, collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
