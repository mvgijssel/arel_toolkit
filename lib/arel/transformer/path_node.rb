module Arel
  module Transformer
    class PathNode
      attr_reader :method
      attr_reader :value

      def initialize(method, value)
        @method = method
        @value = value
      end

      def inspect
        case value
        when String
          "\"#{value}\""
        else
          value.inspect
        end
      end
    end
  end
end
