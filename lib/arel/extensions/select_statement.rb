# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    Arel::Nodes::SelectStatement.class_eval do
      # For INSERT statements
      attr_accessor :values_lists
      attr_accessor :union
      attr_writer :cores
    end
  end

  module Visitors
    class ToSql
      alias old_visit_Nodes_SelectStatement visit_Arel_Nodes_SelectStatement
      def visit_Arel_Nodes_SelectStatement(o, collector)
        visit(o.union, collector) if o.union
        old_visit_Nodes_SelectStatement(o, collector)
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
