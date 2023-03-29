# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/10/functions-string.html
    class Overlay < Arel::Nodes::Node
      attr_reader :string, :substring, :start, :length

      def initialize(string, substring, start, length = nil)
        @string = string
        @substring = substring
        @start = start
        @length = length
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Overlay(o, collector)
        collector << 'overlay('
        visit o.string, collector
        collector << ' placing '
        visit o.substring, collector
        collector << ' from '
        visit o.start, collector
        unless o.length.nil?
          collector << ' for '
          visit o.length, collector
        end
        collector << ')'
      end
    end

    class Dot
      def visit_Arel_Nodes_Overlay(o)
        visit_edge o, 'string'
        visit_edge o, 'substring'
        visit_edge o, 'start'
        visit_edge o, 'length'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
