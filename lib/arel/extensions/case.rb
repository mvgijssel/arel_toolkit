# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

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
# rubocop:enable Naming/UncommunicativeMethodParamName
