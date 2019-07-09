module Arel
  module Transformer
    class Path
      attr_reader :method
      attr_reader :inspect

      def initialize(method, inspect)
        @method = method
        @inspect = inspect
      end
    end
  end
end
