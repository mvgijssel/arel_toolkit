module Arel
  module Nodes
    class Unknown < Arel::Nodes::Node
    end

    class Array < Arel::Nodes::Node
      attr_reader :items

      def initialize(items)
        super()

        @items = items
      end
    end

    class CurrentDate < Arel::Nodes::Node
    end

    class CurrentTimestamp < Arel::Nodes::Node
    end

    class CurrentTime < Arel::Nodes::Node
      attr_reader :precision

      def initialize(precision: nil)
        super()

        @precision = precision
      end
    end
  end
end
