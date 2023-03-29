module Arel
  module Enhance
    class PathNode
      attr_reader :method, :value

      def initialize(method, value)
        @method = method
        @value = value
      end

      def arguments?
        method.is_a?(Array)
      end

      def inspect
        case value
        when String
          "'#{value}'"
        else
          value.inspect
        end
      end
    end
  end
end
