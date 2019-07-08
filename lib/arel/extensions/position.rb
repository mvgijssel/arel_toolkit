# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.1/functions-string.html#FUNCTIONS-STRING-SQL
    class Position < Arel::Nodes::Node
      attr_reader :substring
      attr_reader :string

      sig { params(substring: T.any(Arel::Nodes::Quoted, Arel::Nodes::TypeCast), string: T.any(Arel::Nodes::Quoted, Arel::Nodes::TypeCast)).void }
      def initialize(substring, string)
        @substring = substring
        @string = string
      end
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::Position, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_Position(o, collector)
        collector << 'position('
        visit o.substring, collector
        collector << ' in '
        visit o.string, collector
        collector << ')'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName