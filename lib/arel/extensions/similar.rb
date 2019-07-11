# typed: true
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # Postgres: https://www.postgresql.org/docs/9/functions-matching.html
    class Similar < Arel::Nodes::Matches
      sig do
        params(
          left: Arel::Nodes::Quoted,
          right: Arel::Nodes::Quoted,
          escape: T.nilable(Arel::Nodes::Quoted),
        ).void
      end
      def initialize(left, right, escape = nil)
        super(left, right, escape, false)
      end
    end
  end

  module Visitors
    class ToSql
      sig { params(o: Arel::Nodes::Similar, collector: Arel::Collectors::SQLString).returns(Arel::Collectors::SQLString) }
      def visit_Arel_Nodes_Similar(o, collector)
        visit o.left, collector
        collector << ' SIMILAR TO '
        visit o.right, collector
        if o.escape
          collector << ' ESCAPE '
          visit o.escape, collector
        else
          collector
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
