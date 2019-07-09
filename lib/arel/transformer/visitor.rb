module Arel
  module Transformer
    # rubocop:disable Naming/MethodName
    class Visitor < Arel::Visitors::Dot
      def accept(object)
        root_node = Arel::Transformer::Node.new(object)

        with_node(root_node) do
          visit object
        end

        root_node
      end

      private

      def visit_edge(object, method)
        arel_node = object.send(method)

        process_node(arel_node, Arel::Transformer::PathNode.new(method, method))
      end

      def nary(object)
        visit_edge(object, 'children')
      end
      alias visit_Arel_Nodes_And nary

      def visit_Hash(object)
        object.each do |key, value|
          process_node(value, Arel::Transformer::PathNode.new([:[], key], key))
        end
      end

      def visit_Array(object)
        object.each_with_index do |child, index|
          process_node(child, Arel::Transformer::PathNode.new([:[], index], index))
        end
      end

      def process_node(arel_node, path_node)
        node = Arel::Transformer::Node.new(arel_node)
        current_node.add(path_node, node)

        with_node node do
          visit arel_node
        end
      end

      def visit(object)
        Arel::Visitors::Visitor.instance_method(:visit).bind(self).call(object)
      end

      def current_node
        @node_stack.last
      end
    end
    # rubocop:enable Naming/MethodName
  end
end
