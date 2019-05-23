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

    class CurrentTimestamp < Arel::Nodes::Node
    end

    class CurrentTime < Arel::Nodes::Node
      attr_reader :precision

      def initialize(precision: nil)
        super()

        @precision = precision
      end
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
  end
end
