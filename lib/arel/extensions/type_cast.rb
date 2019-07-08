# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.1/sql-expressions.html
    class TypeCast < Arel::Nodes::Node
      attr_reader :arg
      attr_reader :type_name

      sig { params(arg: T.any(Arel::Nodes::Array, Arel::Nodes::Quoted, Arel::Nodes::SqlLiteral, Integer, Arel::Nodes::UnboundColumnReference, Arel::Attributes::Attribute, Arel::Nodes::Grouping), type_name: String).void }
      def initialize(arg, type_name)
        @arg = arg
        @type_name = type_name
      end

      sig { params(other: Arel::Nodes::TypeCast).returns(T::Boolean) }
      def ==(other)
        arg == other.arg && type_name == other.type_name
      end
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::TypeCast, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_TypeCast(o, collector)
        visit o.arg, collector
        collector << '::'
        collector << o.type_name
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName