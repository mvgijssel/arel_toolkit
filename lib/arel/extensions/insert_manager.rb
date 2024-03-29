# rubocop:disable Naming/MethodName

module Arel
  class InsertManager < Arel::TreeManager
    def ==(other)
      other.is_a?(self.class) && @ast == other.ast
    end
  end

  module Visitors
    class Dot
      def visit_Arel_InsertManager(o)
        visit_edge o, 'ast'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
