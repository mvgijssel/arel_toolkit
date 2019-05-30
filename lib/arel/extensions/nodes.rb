# rubocop:disable Metrics/ParameterLists
# rubocop:disable Naming/UncommunicativeMethodParamName
# rubocop:disable Metrics/ModuleLength

module Arel
  module Nodes
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
