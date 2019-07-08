# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-math.html
    class Factorial < Arel::Nodes::Unary
      attr_accessor :prefix

      sig { params(expr: T.any(Integer, Arel::Nodes::TypeCast), prefix: T::Boolean).void }
      def initialize(expr, prefix)
        super(expr)
        @prefix = prefix
      end
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::Factorial, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
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