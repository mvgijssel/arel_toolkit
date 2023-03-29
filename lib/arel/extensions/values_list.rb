# rubocop:disable Naming/MethodName

module Arel
  module Visitors
    class Dot
      def visit_Arel_Nodes_ValuesList(o)
        visit_edge o, 'rows'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
