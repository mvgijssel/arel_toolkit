# rubocop:disable Naming/MethodName

module Arel
  module Visitors
    class ToSql
      def visit_Arel_Nodes_NamedFunction(o, collector)
        aggregate(o.name, o, collector)
      end
    end

    class Dot
      def visit_Arel_Nodes_NamedFunction(o)
        visit_edge o, 'name'
        function(o)
      end
    end
  end
end

# rubocop:enable Naming/MethodName
