# rubocop:disable Naming/MethodName

module Arel
  module Visitors
    class Dot
      def visit_Arel_Nodes_BindParam(o)
        visit_edge o, 'value'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
