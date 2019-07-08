# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Visitors
    class ToSql
      sig { params(o: T.any(Arel::Nodes::NamedFunction, Arel::Nodes::Coalesce, Arel::Nodes::Least, Arel::Nodes::Greatest, Arel::Nodes::Rank, Arel::Nodes::GenerateSeries), collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_NamedFunction(o, collector)
        aggregate(o.name, o, collector)
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName