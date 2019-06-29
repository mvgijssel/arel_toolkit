# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/10/functions-string.html
    class Overlaps < Arel::Nodes::Node
      attr_reader :start1
      attr_reader :end1
      attr_reader :start2
      attr_reader :end2

      def initialize(start1, end1, start2, end2)
        @start1 = start1
        @end1 = end1
        @start2 = start2
        @end2 = end2
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Overlaps(o, collector)
        collector << '('
        visit o.start1, collector
        collector << ', '
        visit o.end1, collector
        collector << ') OVERLAPS ('
        visit o.start2, collector
        collector << ', '
        visit o.end2, collector
        collector << ')'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
