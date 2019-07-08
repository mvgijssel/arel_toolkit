# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName
module Arel
  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::Assignment, collector: T.any(Arel::Collectors::SQLString, Arel::Collectors::Composite)).returns(T.any(Arel::Collectors::SQLString, Arel::Collectors::Composite)) }
      def visit_Arel_Nodes_Assignment(o, collector)
        collector = visit o.left, collector
        collector << ' = '

        case o.right
        when Arel::Nodes::Node, Arel::Attributes::Attribute
          visit o.right, collector
        else
          collector << quote(o.right).to_s
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName