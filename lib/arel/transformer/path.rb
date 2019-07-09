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

    class Path
      attr_reader :nodes

      def initialize(nodes = [])
        @nodes = nodes
      end

      def append(path_node)
        Path.new(nodes + [path_node])
      end

      def current
        nodes.last
      end

      def inspect
        nodes.inspect
        string = '['
        string << nodes.map(&:inspect).join(', ')
        string << ']'
      end
    end
  end
end
