module Arel
  module Nodes
    class GenerateSeries < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'GENERATE_SERIES', args
      end
    end
  end
end
