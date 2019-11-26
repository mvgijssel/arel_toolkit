module Arel
  module Enhance
    class Path
      attr_reader :nodes

      def initialize(nodes = [])
        @nodes = nodes
      end

      def append(path_node)
        Path.new(nodes + [path_node])
      end

      def dig_send(object)
        selected_object = object
        nodes.each { |path_node| selected_object = selected_object.send(*path_node.method) }
        selected_object
      end

      def to_a
        nodes.map(&:value)
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
