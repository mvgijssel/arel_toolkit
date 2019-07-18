# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/10/functions-string.html
    class Trim < Arel::Nodes::Node
      attr_reader :type
      attr_reader :substring
      attr_reader :string

      def initialize(type, substring, string)
        @type = type
        @substring = substring
        @string = string
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Trim(o, collector)
        collector << "trim(#{o.type} "
        if o.substring
          visit o.substring, collector
          collector << ' from '
        end
        visit o.string, collector
        collector << ')'
      end
    end

    class Dot
      def visit_Arel_Nodes_Trim(o)
        visit_edge o, 'type'
        visit_edge o, 'substring'
        visit_edge o, 'string'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
