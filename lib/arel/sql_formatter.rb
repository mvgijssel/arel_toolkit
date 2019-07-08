# typed: true
module Arel
  module Nodes
    class Node
      sig { params(engine: T.untyped).returns(T.untyped) }
      def to_formatted_sql(engine = Table.engine)
        collector = Arel::Collectors::SQLString.new
        Arel::SqlFormatter.new(engine.connection).accept self, collector
        collector.value
      end
    end
  end

  class TreeManager
    sig { params(engine: Class).returns(String) }
    def to_formatted_sql(engine = Table.engine)
      collector = Arel::Collectors::SQLString.new
      Arel::SqlFormatter.new(engine.connection).accept @ast, collector
      collector.value
    end
  end

  class SqlFormatter < Arel::Visitors::PostgreSQL
    sig { params(object: Arel::Nodes::SelectStatement, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
    def accept(object, collector)
      super object, collector
      collector << "\n"
    end

    private

    # rubocop:disable Naming/MethodName
    # rubocop:disable Naming/UncommunicativeMethodParamName
    # rubocop:disable Metrics/AbcSize
    sig { params(o: Arel::Nodes::SelectCore, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
    def visit_Arel_Nodes_SelectCore(o, collector)
      collector << "SELECT\n"

      collector = maybe_visit o.top, collector

      collector = maybe_visit o.set_quantifier, collector

      collect_nodes_for(o.projections, collector, SPACE, ",\n")

      if o.source && !o.source.empty?
        collector << ' FROM '
        collector = visit o.source, collector
      end

      collect_nodes_for o.wheres, collector, WHERE, AND
      collect_nodes_for o.groups, collector, GROUP_BY
      unless o.havings.empty?
        collector << ' HAVING '
        inject_join o.havings, collector, AND
      end
      collect_nodes_for o.windows, collector, WINDOW

      collector
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Naming/MethodName
    # rubocop:enable Naming/UncommunicativeMethodParamName
  end
end