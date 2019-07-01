module Arel
  module Nodes
    # https://www.postgresql.org/docs/9.4/functions-json.html#FUNCTIONS-JSON-OP-TABLE
    class JsonGetField < Arel::Nodes::InfixOperation
      def initialize(left, right)
        super(:'->>', left, right)
      end
    end
  end
end
