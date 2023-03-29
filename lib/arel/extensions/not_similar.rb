# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9/functions-matching.html
    class NotSimilar < Arel::Nodes::Similar
    end
  end

  module Visitors
    class ToSql
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
