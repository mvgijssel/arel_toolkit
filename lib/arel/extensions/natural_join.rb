# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class NaturalJoin < Arel::Nodes::Join
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_NaturalJoin(o, collector)
        collector << 'NATURAL JOIN '
        visit o.left, collector
      end
    end
  end
end

# rubocop:enable Naming/MethodName
