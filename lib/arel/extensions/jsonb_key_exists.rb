# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-json.html#FUNCTIONS-JSONB-OP-TABLE
    class JsonbKeyExists < Arel::Nodes::Binary
    end
  end

  module Visitors
    class ToSql
      # TODO: extend operators from < InfixOperation
      # then we have a free visitor method!
      def visit_Arel_Nodes_JsonbKeyExists(o, collector)
        infix_value o, collector, ' ? '
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
