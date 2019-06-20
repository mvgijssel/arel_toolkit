# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName
module Arel
  module Visitors
    class ToSql
      alias old_visit_Arel_Nodes_Assignment visit_Arel_Nodes_Assignment
      def visit_Arel_Nodes_Assignment(o, collector)
        case o.right
        when Arel::Nodes::TypeCast,
             Arel::Nodes::SetToDefault,
             Arel::Nodes::Grouping,
             Arel::Nodes::Row,
             Arel::Nodes::Quoted

          collector = visit o.left, collector
          collector << ' = '
          visit o.right, collector
        else
          old_visit_Arel_Nodes_Assignment(o, collector)
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
