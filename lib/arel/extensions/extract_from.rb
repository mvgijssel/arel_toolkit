# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.1/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT
    class ExtractFrom < Arel::Nodes::Unary
      attr_reader :field

      def initialize(expr, field)
        super(expr)

        @field = field
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_ExtractFrom(o, collector)
        collector << 'extract('
        visit o.field, collector
        collector << ' from '
        visit o.expr, collector
        collector << ')'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
