# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

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
# rubocop:enable Naming/UncommunicativeMethodParamName
