# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/10/functions-string.html
    class Overlay < Arel::Nodes::Node
      attr_reader :string
      attr_reader :substring
      attr_reader :start
      attr_reader :length

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
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
