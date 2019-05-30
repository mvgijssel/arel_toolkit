module Arel
  module Nodes
    class Least < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'LEAST', args
      end
    end
  end
end
