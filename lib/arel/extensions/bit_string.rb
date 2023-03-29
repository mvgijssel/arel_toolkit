# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class BitString < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_BitString(o, collector)
        collector << "B'#{o.expr[1..-1]}'"
      end
    end
  end
end

# rubocop:enable Naming/MethodName
