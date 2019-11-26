# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class CrossJoin < Arel::Nodes::Join; end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_CrossJoin(o, collector)
        collector << 'CROSS JOIN '
        visit o.left, collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
