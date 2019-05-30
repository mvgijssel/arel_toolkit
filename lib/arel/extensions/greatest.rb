module Arel
  module Nodes
    class Greatest < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'GREATEST', args
      end
    end
  end
end
