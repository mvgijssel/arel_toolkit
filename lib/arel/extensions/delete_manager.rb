# rubocop:disable Naming/MethodName

module Arel
  class DeleteManager < Arel::TreeManager
    def ==(other)
      other.is_a?(self.class) && @ast == other.ast && @ctx == other.ctx
    end

    protected

    attr_reader :ctx
  end

  module Visitors
    class Dot
      def visit_Arel_DeleteManager(o)
        visit_edge o, 'ast'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
