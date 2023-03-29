# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-math.html
    class Factorial < Arel::Nodes::Node
      attr_accessor :prefix, :expr

      def initialize(expr, prefix)
        @expr = expr
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

    class Dot
      def visit_Arel_Nodes_Factorial(o)
        visit_edge o, 'expr'
        visit_edge o, 'prefix'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
