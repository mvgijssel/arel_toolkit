# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class CurrentTimestamp < TimeWithPrecision
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::CurrentTimestamp, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_CurrentTimestamp(o, collector)
        collector << 'current_timestamp'
        collector << "(#{o.precision.to_i})" if o.precision
        collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName