# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  class UpdateManager < Arel::TreeManager
    def ==(other)
      @ast == other.ast && @ctx == other.ctx
    end

    protected

    attr_reader :ctx
  end

  module Visitors
    class Dot
      def visit_Arel_UpdateManager(o)
        visit_edge o, 'ast'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
