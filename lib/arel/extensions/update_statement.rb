# typed: false
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/10/sql-update.html
    Arel::Nodes::UpdateStatement.class_eval do
      attr_accessor :with
      attr_accessor :froms
      attr_accessor :returning

      alias_method :old_initialize, :initialize
      sig { void }
      def initialize
        old_initialize

        @froms = []
        @returning = []
      end
    end
  end

  module Visitors
    class ToSql
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/PerceivedComplexity
      sig { params(o: Arel::Nodes::UpdateStatement, collector: T.any(Arel::Collectors::SQLString, Arel::Collectors::Composite)).returns(T.any(Arel::Collectors::SQLString, Arel::Collectors::Composite)) }
      def visit_Arel_Nodes_UpdateStatement(o, collector)
        if o.with
          collector = visit o.with, collector
          collector << SPACE
        end

        wheres = if o.orders.empty? && o.limit.nil?
                   o.wheres
                 else
                   [Nodes::In.new(o.key, [build_subselect(o.key, o)])]
                 end

        collector << 'UPDATE '
        collector = visit o.relation, collector
        unless o.values.empty?
          collector << ' SET '
          collector = inject_join o.values, collector, ', '
        end

        unless o.froms.empty?
          collector << ' FROM '
          collector = inject_join o.froms, collector, ', '
        end

        unless wheres.empty?
          collector << ' WHERE '
          collector = inject_join wheres, collector, ' AND '
        end

        unless o.returning.empty?
          collector << ' RETURNING '
          collector = inject_join o.returning, collector, ', '
        end

        collector
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName