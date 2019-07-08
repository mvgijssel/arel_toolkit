# typed: true
module Arel
  module Nodes
    class TimeWithPrecision < Arel::Nodes::Node
      attr_reader :precision

      sig { params(precision: Integer).void }
      def initialize(precision: nil)
        super()

        @precision = precision
      end
    end
  end
end