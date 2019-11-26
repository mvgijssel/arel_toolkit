# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    class LocalTime < TimeWithPrecision; end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_LocalTime(o, collector)
        collector << 'localtime'
        collector << "(#{o.precision.to_i})" if o.precision
        collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
