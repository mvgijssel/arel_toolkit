# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/10/functions-string.html
    class Trim < Arel::Nodes::Node
      attr_reader :type
      attr_reader :substring
      attr_reader :string

      sig { params(type: String, substring: T.nilable(Arel::Nodes::Quoted, Arel::Nodes::TypeCast), string: T.any(Arel::Nodes::Quoted, Arel::Nodes::TypeCast)).void }
      def initialize(type, substring, string)
        @type = type
        @substring = substring
        @string = string
      end
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::Trim, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
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
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName