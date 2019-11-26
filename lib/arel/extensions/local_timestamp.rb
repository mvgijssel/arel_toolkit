# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class LocalTimestamp < TimeWithPrecision; end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_LocalTimestamp(o, collector)
        collector << 'localtimestamp'
        collector << "(#{o.precision.to_i})" if o.precision
        collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
