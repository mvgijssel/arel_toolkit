# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.1/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT
    class ExtractFrom < Arel::Nodes::Binary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_ExtractFrom(o, collector)
        collector << 'extract('
        visit o.right, collector
        collector << ' from '
        visit o.left, collector
        collector << ')'
      end
    end
  end
end

# rubocop:enable Naming/MethodName
