# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class Array < Arel::Nodes::Unary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Array(o, collector)
        collector << 'ARRAY['
        inject_join(o.expr, collector, ', ')
        collector << ']'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
