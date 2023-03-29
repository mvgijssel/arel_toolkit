# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class CurrentTime < TimeWithPrecision
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_CurrentTime(o, collector)
        collector << 'current_time'
        collector << "(#{o.precision.to_i})" if o.precision
        collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
