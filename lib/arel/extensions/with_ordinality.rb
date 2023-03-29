# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # Postgres: https://paquier.xyz/postgresql-2/postgres-9-4-feature-highlight-with-ordinality/
    class WithOrdinality < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_WithOrdinality(o, collector)
        visit o.expr, collector
        collector << ' WITH ORDINALITY'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
