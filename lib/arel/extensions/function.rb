# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9.1/functions-comparison.html
    class Function
      module FunctionExtension
        # postgres only: https://www.postgresql.org/docs/9.5/functions-aggregate.html
        attr_accessor :orders
        attr_accessor :filter
        attr_accessor :within_group
        attr_accessor :variardic
        # postgres only: https://www.postgresql.org/docs/10/ddl-schemas.html
        attr_accessor :schema_name

        def initialize(expr, aliaz = nil)
          super

          @expressions = expr
          @alias       = aliaz && SqlLiteral.new(aliaz)
          @distinct    = false
          @orders      = []
        end
      end

      prepend FunctionExtension
    end
  end

  module Visitors
    class ToSql
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      def aggregate(name, o, collector)
        collector << "#{o.schema_name}." if o.schema_name
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

    class Dot
      module FunctionExtension
        def function(o)
          super

          visit_edge o, 'orders'
          visit_edge o, 'filter'
          visit_edge o, 'within_group'
          visit_edge o, 'variardic'
        end

        alias visit_Arel_Nodes_Exists function
        alias visit_Arel_Nodes_Min    function
        alias visit_Arel_Nodes_Max    function
        alias visit_Arel_Nodes_Avg    function
        alias visit_Arel_Nodes_Sum    function
      end

      prepend FunctionExtension
    end
  end
end

# rubocop:enable Naming/UncommunicativeMethodParamName
