# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.1/sql-show.html
    class VariableShow < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_VariableShow(o, collector)
        collector << 'SHOW '
        collector << if o.expr == 'timezone'
                       'TIME ZONE'
                     else
                       o.expr
                     end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
