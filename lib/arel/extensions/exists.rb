# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # This is a copy of https://github.com/rails/arel/blob/v9.0.0/lib/arel/nodes/function.rb
    # Only difference is the superclass, because EXISTS is not a function but a subquery expression.
    # Semantic meaning is important when transforming the Arel using the enhanced AST,
    # because EXISTS cannot be processed as a function. For example it does not have a schema
    # like a normal function.
    #
    # To change the superclass we're removing the existing Exists class `Arel::Nodes::Exists`
    # and recreating it extending from `Arel::Nodes::Unary`.
    remove_const(:Exists)

    # https://www.postgresql.org/docs/10/functions-subquery.html
    class Exists < Arel::Nodes::Unary
      include Arel::Predications
      include Arel::WindowPredications
      include Arel::OrderPredications
      attr_accessor :expressions, :alias, :distinct

      def initialize(expr, aliaz = nil)
        @expressions = expr
        @alias = aliaz && SqlLiteral.new(aliaz)
        @distinct = false
      end

      def as(aliaz)
        self.alias = SqlLiteral.new(aliaz)
        self
      end

      def hash
        [@expressions, @alias, @distinct].hash
      end

      def eql?(other)
        self.class == other.class && expressions == other.expressions &&
          self.alias == other.alias &&
          distinct == other.distinct
      end
      alias == eql?
    end
  end

  module Visitors
    class Dot
      def visit_Arel_Nodes_Exists(o)
        visit_edge o, 'expressions'
        visit_edge o, 'alias'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
