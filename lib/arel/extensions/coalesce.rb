module Arel
  module Nodes
    class Coalesce < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'COALESCE', args
      end
    end
  end
end
