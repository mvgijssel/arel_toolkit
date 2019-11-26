# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.1/sql-show.html
    class VariableShow < Arel::Nodes::Unary; end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_VariableShow(o, collector)
        collector << 'SHOW '
        collector << (o.expr == 'timezone' ? 'TIME ZONE' : o.expr)
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
