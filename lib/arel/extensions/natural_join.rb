# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class NaturalJoin < Arel::Nodes::Join
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::NaturalJoin, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_NaturalJoin(o, collector)
        collector << 'NATURAL JOIN '
        visit o.left, collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName