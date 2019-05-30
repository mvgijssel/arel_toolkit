# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class Infer < Arel::Nodes::Node
      attr_accessor :name
      attr_accessor :indexes
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Infer(o, collector)
        if o.name
          collector << 'ON CONSTRAINT '
          collector << o.name
          collector << SPACE
        end

        if o.indexes
          collector << '('
          inject_join o.indexes, collector, ', '
          collector << ') '
        end

        collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
