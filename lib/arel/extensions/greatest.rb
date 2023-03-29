# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/10/functions-conditional.html
    class Greatest < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Greatest(o, collector)
        collector << 'GREATEST('
        collector = inject_join(o.expr, collector, ', ')
        collector << ')'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
