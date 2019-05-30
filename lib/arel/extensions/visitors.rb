# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Visitors
    class ToSql
      private

      def visit_Arel_Nodes_NotEqual(o, collector)
        right = o.right

        collector = visit o.left, collector

        case right
        when Arel::Nodes::Unknown, Arel::Nodes::False, Arel::Nodes::True
          collector << ' IS NOT '
          visit right, collector

        when NilClass
          collector << ' IS NOT NULL'

        else
          collector << ' != '
          visit right, collector
        end
      end

      def visit_Arel_Nodes_Equality(o, collector)
        right = o.right

        collector = visit o.left, collector

        case right
        when Arel::Nodes::Unknown, Arel::Nodes::False, Arel::Nodes::True
          collector << ' IS '
          visit right, collector

        when NilClass
          collector << ' IS NULL'

        else
          collector << ' = '
          visit right, collector
        end
      end

      def visit_Arel_Nodes_NamedFunction(o, collector)
        aggregate(o.name, o, collector)
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
