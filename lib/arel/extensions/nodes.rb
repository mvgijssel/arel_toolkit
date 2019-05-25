module Arel
  module Nodes
    class Unknown < Arel::Nodes::Node
    end

    class Array < Arel::Nodes::Node
      attr_reader :items

      def initialize(items)
        super()

        @items = items
      end
    end

    class Indirection < Arel::Nodes::Node
      attr_reader :arg
      attr_reader :indirection

      def initialize(arg, indirection)
        super()

        @arg = arg
        @indirection = indirection
      end
    end

    class BitString < Arel::Nodes::Node
      attr_reader :str

      def initialize(str)
        super()

        @str = str
      end
    end

    class CurrentDate < Arel::Nodes::Node
    end

    class TimeWithPrecision < Arel::Nodes::Node
      attr_reader :precision

      def initialize(precision: nil)
        super()

        @precision = precision
      end
    end

    class CurrentTimestamp < TimeWithPrecision
    end

    class CurrentTime < TimeWithPrecision
    end

    class LocalTime < TimeWithPrecision
    end

    class LocalTimeStamp < TimeWithPrecision
    end

    class CurrentRole < Arel::Nodes::Node
    end

    class CurrentUser < Arel::Nodes::Node
    end

    class SessionUser < Arel::Nodes::Node
    end

    class User < Arel::Nodes::Node
    end

    class CurrentCatalog < Arel::Nodes::Node
    end

    class CurrentSchema < Arel::Nodes::Node
    end

    class NaturalJoin < Arel::Nodes::Join
    end

    class CrossJoin < Arel::Nodes::Join
    end

    # TODO: currently in Arel master, remove in time
    class Lateral < Arel::Nodes::Unary
    end

    # Only exists in Postgres https://www.postgresql.org/docs/9.4/sql-select.html
    class RangeFunction < Arel::Nodes::Unary
    end

    # postgres only: https://paquier.xyz/postgresql-2/postgres-9-4-feature-highlight-with-ordinality/
    class WithOrdinality < Arel::Nodes::Unary
    end

    Arel::Table.class_eval do
      # postgres only: https://www.postgresql.org/docs/9.5/sql-select.html
      attr_accessor :only
      # postgres only: https://www.postgresql.org/docs/9.5/ddl-schemas.html
      attr_accessor :schema_name
      # postgres only: https://www.postgresql.org/docs/9.1/catalog-pg-class.html
      attr_accessor :relpersistence

      alias_method :old_initialize, :initialize
      def initialize(name, as: nil, type_caster: nil, only: false, schema_name: nil, relpersistence: 'p')
        @only = only
        @schema_name = schema_name
        @relpersistence = relpersistence

        old_initialize(name, as: as, type_caster: type_caster)
      end
    end

    # postgres only: https://www.postgresql.org/docs/9.2/sql-expressions.html
    class Row < Arel::Nodes::Unary
      attr_reader :row_format

      def initialize(args, row_format)
        super(args)

        @row_format = row_format
      end
    end

    Arel::Nodes::Ordering.class_eval do
      # postgres only: https://www.postgresql.org/docs/9.4/queries-order.html
      attr_accessor :nulls

      alias_method :old_initialize, :initialize
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
  end
end
