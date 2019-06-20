# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-json.html#FUNCTIONS-JSONB-OP-TABLE
    class JsonbAllKeyExists < Arel::Nodes::Binary
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_JsonbAllKeyExists(o, collector)
        infix_value o, collector, ' ?& '
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
