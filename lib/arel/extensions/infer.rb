# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.5/sql-insert.html
    class Infer < Arel::Nodes::Binary
      alias name left
      alias indexes right
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_Infer(o, collector)
        if o.name
          collector << 'ON CONSTRAINT '
          collector << o.left
          collector << SPACE
        end

        if o.right
          collector << '('
          inject_join o.right, collector, ', '
          collector << ') '
        end

        collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
