# rubocop:disable Naming/MethodName

module Arel
  module Visitors
    class Dot
      def visit_Arel_Nodes_Case(o)
        visit_edge o, 'case'
        visit_edge o, 'conditions'
        visit_edge o, 'default'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
