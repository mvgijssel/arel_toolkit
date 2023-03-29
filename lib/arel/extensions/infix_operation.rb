# rubocop:disable Naming/MethodName

module Arel
  module Visitors
    class Dot
      def visit_Arel_Nodes_InfixOperation(o)
        visit_edge o, 'operator'
        visit_edge o, 'left'
        visit_edge o, 'right'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
