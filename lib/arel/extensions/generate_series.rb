# typed: true
module Arel
  module Nodes
    class GenerateSeries < Arel::Nodes::NamedFunction
      sig { params(args: T::Array[Integer]).void }
      def initialize(args)
        super 'GENERATE_SERIES', args
      end
    end
  end
end