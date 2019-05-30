module Arel
  module Nodes
    class Rank < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'RANK', args
      end
    end
  end
end
