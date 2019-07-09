module Arel
  module Transformer
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
