module Arel
  module Nodes
    class Rank < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'RANK', args
      end
    end

    class Coalesce < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'COALESCE', args
      end
    end
  end
end
