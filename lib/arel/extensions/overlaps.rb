# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/10/functions-string.html
    inheritance_class = if Gem.loaded_specs['activerecord'].version < Gem::Version.new('6.1.0')
                          Arel::Nodes::Node
                        else
                          Arel::Nodes::InfixOperation
                        end

    class Overlaps < inheritance_class
      attr_reader :start1, :end1, :start2, :end2

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

    class Dot
      def visit_Arel_Nodes_Overlaps(o)
        visit_edge o, 'start1'
        visit_edge o, 'end1'
        visit_edge o, 'start2'
        visit_edge o, 'end2'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
