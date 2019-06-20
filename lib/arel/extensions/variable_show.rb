# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.1/sql-show.html
    class VariableShow < Arel::Nodes::Node
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_VariableShow(o, collector)
        collector << 'SHOW '
        collector << if o.name == 'timezone'
                       'TIME ZONE'
                     else
                       o.name
                     end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
