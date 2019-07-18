# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  class InsertManager < Arel::TreeManager
    def ==(other)
      @ast == other.ast
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
# rubocop:enable Naming/UncommunicativeMethodParamName
