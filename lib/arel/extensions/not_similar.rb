# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9/functions-matching.html
    class NotSimilar < Arel::Nodes::Similar
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::NotSimilar, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_NotSimilar(o, collector)
        visit o.left, collector
        collector << ' NOT SIMILAR TO '
        visit o.right, collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName