# typed: true
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.1/functions-comparison.html
    Arel::Nodes::Function.class_eval do
      # postgres only: https://www.postgresql.org/docs/9.5/functions-aggregate.html
      attr_accessor :orders
      attr_accessor :filter
      attr_accessor :within_group
      attr_accessor :variardic

      sig {
        params(
          expr: T.any(T::Array, Arel::Nodes::SelectStatement),
          aliaz: T.nilable(T.untyped)
        ).void
      }
      def initialize(expr, aliaz = nil)
        super()
        @expressions = expr
        @alias       = aliaz && SqlLiteral.new(aliaz)
        @distinct    = false
        @orders      = []
      end
    end
  end

  module Visitors
    class ToSql
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      sig {
        params(
          name: String,
          o: T.any(
            Arel::Nodes::NamedFunction,
            Arel::Nodes::Sum,
            Arel::Nodes::Coalesce,
            Arel::Nodes::Avg, Arel::Nodes::Least,
            Arel::Nodes::Greatest,
            Arel::Nodes::Rank, Arel::Nodes::Count,
            Arel::Nodes::GenerateSeries,
            Arel::Nodes::Max,
            Arel::Nodes::Min
          ),
          collector: Arel::Collectors::SQLString,
        ).returns(Arel::Collectors::SQLString)
      }
      def aggregate(name, o, collector)
        collector << "#{name}("
        collector << 'DISTINCT ' if o.distinct
        collector << 'VARIADIC ' if o.variardic

        collector = inject_join(o.expressions, collector, ', ')

        if o.within_group
          collector << ')'
          collector << ' WITHIN GROUP ('
        end

        if o.orders.any?
          collector << SPACE unless o.within_group
          collector << 'ORDER BY '
          collector = inject_join o.orders, collector, ', '
        end

        collector << ')'

        if o.filter
          collector << ' FILTER(WHERE '
          visit o.filter, collector
          collector << ')'
        end

        if o.alias
          collector << ' AS '
          visit o.alias, collector
        else
          collector
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize
    end
  end
end

# rubocop:enable Naming/UncommunicativeMethodParamName
