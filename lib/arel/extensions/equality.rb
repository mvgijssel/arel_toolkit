# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Visitors
    class ToSql
      def visit_Arel_Nodes_Equality(o, collector)
        right = o.right
        collector = visit o.left, collector

        if [Arel::Nodes::Unknown, Arel::Nodes::False, Arel::Nodes::True].include?(right.class)
          collector << ' IS '
          visit right, collector

        elsif right.nil?
          collector << ' IS NULL'

        else
          collector << ' = '
          visit right, collector
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
