# rubocop:disable Metrics/ParameterLists
# rubocop:disable Naming/UncommunicativeMethodParamName
# rubocop:disable Metrics/ModuleLength

module Arel
  module Nodes
    Arel::Nodes::Ordering.class_eval do
      # postgres only: https://www.postgresql.org/docs/9.4/queries-order.html
      attr_accessor :nulls

      def initialize(expr, nulls = 0)
        super(expr)

        @nulls = nulls
      end
    end

    # postgres only: https://www.postgresql.org/docs/8.1/sql-select.html
    class All < Arel::Nodes::Unary
    end

    # postgres only: https://www.postgresql.org/docs/9.1/functions-comparisons.html
    class Any < Arel::Nodes::Unary
    end

    # postgres only: https://www.postgresql.org/docs/9.1/functions-comparisons.html
    class ArraySubselect < Arel::Nodes::Unary
    end

    # postgres only: https://www.postgresql.org/docs/9.1/sql-expressions.html
    class TypeCast < Arel::Nodes::Node
      attr_reader :arg
      attr_reader :type_name

      def initialize(arg, type_name)
        @arg = arg
        @type_name = type_name
      end
    end

    class DistinctFrom < Arel::Nodes::Binary
    end

    class NotDistinctFrom < Arel::Nodes::Binary
    end

    class NullIf < Arel::Nodes::Binary
    end

    # postgres only: https://www.postgresql.org/docs/9/functions-matching.html
    class Similar < Arel::Nodes::Matches
      def initialize(left, right, escape = nil)
        super(left, right, escape, false)
      end
    end

    # postgres only: https://www.postgresql.org/docs/9/functions-matching.html
    class NotSimilar < Arel::Nodes::Similar
    end

    class NotBetween < Arel::Nodes::Between
    end

    # postgres only: https://www.postgresql.org/docs/9.1/functions-comparison.html
    class BetweenSymmetric < Arel::Nodes::Between
    end

    # postgres only: https://www.postgresql.org/docs/9.1/functions-comparison.html
    class NotBetweenSymmetric < Arel::Nodes::BetweenSymmetric
    end

    Arel::Nodes::Function.class_eval do
      # postgres only: https://www.postgresql.org/docs/9.5/functions-aggregate.html
      attr_accessor :orders
      attr_accessor :filter
      attr_accessor :within_group
      attr_accessor :variardic

      def initialize(expr, aliaz = nil)
        super()
        @expressions = expr
        @alias       = aliaz && SqlLiteral.new(aliaz)
        @distinct    = false
        @orders      = []
      end
    end

    # https://www.postgresql.org/docs/9.4/functions-math.html
    class Factorial < Arel::Nodes::Unary
      attr_accessor :prefix

      def initialize(expr, prefix)
        super(expr)
        @prefix = prefix
      end
    end

    # https://www.postgresql.org/docs/9.4/functions-math.html
    class SquareRoot < Arel::Nodes::UnaryOperation
      def initialize(operand)
        super('|/', operand)
      end
    end

    # https://www.postgresql.org/docs/9.4/functions-math.html
    class CubeRoot < Arel::Nodes::UnaryOperation
      def initialize(operand)
        super('||/', operand)
      end
    end

    # https://www.postgresql.org/docs/9.4/functions-math.html
    class Modulo < Arel::Nodes::InfixOperation
      def initialize(left, right)
        super(:%, left, right)
      end
    end

    # https://www.postgresql.org/docs/9.4/functions-math.html
    class Absolute < Arel::Nodes::UnaryOperation
      def initialize(operand)
        super('@', operand)
      end
    end

    # TODO: `#` is bitwise xor, right? Check out:
    # -> https://www.postgresql.org/docs/9.4/functions-math.html
    # -> https://github.com/rails/rails/blob/master/activerecord/lib/arel/math.rb#L30
    # Am I wrong, or is this a bug in Arel?
    class BitwiseXor < InfixOperation
      def initialize(left, right)
        super('#', left, right)
      end
    end

    # https://www.postgresql.org/docs/9.1/functions-array.html
    class Exponentiation < InfixOperation
      def initialize(left, right)
        super(:^, left, right)
      end
    end

    # https://www.postgresql.org/docs/9.1/functions-array.html
    class Contains < InfixOperation
      def initialize(left, right)
        super('@>', left, right)
      end
    end

    # https://www.postgresql.org/docs/9.1/functions-array.html
    class ContainedBy < InfixOperation
      def initialize(left, right)
        super('<@', left, right)
      end
    end

    # https://www.postgresql.org/docs/9.1/functions-array.html
    class Overlap < InfixOperation
      def initialize(left, right)
        super('&&', left, right)
      end
    end

    Arel::Nodes::SelectStatement.class_eval do
      # For INSERT statements
      attr_accessor :values_lists
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    Arel::Nodes::InsertStatement.class_eval do
      attr_accessor :with
      attr_accessor :on_conflict
      attr_accessor :override
      attr_accessor :returning
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class DefaultValues < Arel::Nodes::Node
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class DefaultValues < Arel::Nodes::Node
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class Conflict < Arel::Nodes::Node
      attr_accessor :action
      attr_accessor :infer
      attr_accessor :values
      attr_accessor :wheres
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class Infer < Arel::Nodes::Node
      attr_accessor :name
      attr_accessor :indexes
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class SetToDefault < Arel::Nodes::Node
    end

    # https://www.postgresql.org/docs/10/sql-update.html
    Arel::Nodes::UpdateStatement.class_eval do
      attr_accessor :with
      attr_accessor :froms
      attr_accessor :returning
    end

    # https://www.postgresql.org/docs/10/sql-update.html
    class CurrentOfExpression < Arel::Nodes::Node
      attr_accessor :cursor_name

      def initialize(cursor_name)
        super()

        @cursor_name = cursor_name
      end
    end

    # https://www.postgresql.org/docs/9.5/sql-insert.html
    Arel::Nodes::DeleteStatement.class_eval do
      attr_accessor :using
      attr_accessor :with
      attr_accessor :returning
    end
  end
end

# rubocop:enable Metrics/ParameterLists
# rubocop:enable Naming/UncommunicativeMethodParamName
# rubocop:enable Metrics/ModuleLength
