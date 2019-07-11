# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/10/functions-string.html
    class Substring < Arel::Nodes::Node
      attr_reader :string
      attr_reader :pattern
      attr_reader :escape

      def initialize(string, pattern, escape)
        @string = string
        @pattern = pattern
        @escape = escape
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Substring(o, collector)
        collector << 'substring('
        visit o.string, collector
        collector << ' from '
        visit o.pattern, collector
        unless o.escape.nil?
          collector << ' for '
          visit o.escape, collector
        end
        collector << ')'
      end
    end

    class Dot
      def visit_Arel_Nodes_Substring(o)
        visit_edge o, 'string'
        visit_edge o, 'pattern'
        visit_edge o, 'escape'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
