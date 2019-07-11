# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Visitors
    class Dot
      def visit_Arel_Nodes_UnaryOperation(o)
        visit_edge o, 'operator'
        visit_edge o, 'expr'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
