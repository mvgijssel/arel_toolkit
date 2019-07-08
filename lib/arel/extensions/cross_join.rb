# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class CrossJoin < Arel::Nodes::Join
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::CrossJoin, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_CrossJoin(o, collector)
        collector << 'CROSS JOIN '
        visit o.left, collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName