# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-math.html
    class Factorial < Arel::Nodes::Unary
      attr_accessor :prefix

      def initialize(expr, prefix)
        super(expr)
        @prefix = prefix
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Factorial(o, collector)
        if o.prefix
          collector << '!! '
          visit o.expr, collector
        else
          visit o.expr, collector
          collector << ' !'
        end
      end
    end
  end
end

# rubocop:enable Naming/UncommunicativeMethodParamName
# rubocop:enable Naming/MethodName
