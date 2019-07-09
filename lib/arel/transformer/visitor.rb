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

    # rubocop:disable Naming/MethodName
    class Visitor < Arel::Visitors::Dot
      # TODO: refactor how nodes are added to each other
      def accept(object, parent = nil, path = nil)
        root_node = Arel::Transformer::Node.new(
          object,
          parent,
          parent.nil? ? [] : parent.path + [path],
          parent.nil? ? nil : parent.root_node,
        )

        with_node(root_node) do
          visit object
        end

        root_node
      end

      private

      def visit_edge(object, method)
        arel_node = object.send(method)

        process_node(arel_node, Path.new(method, method))
      end

      def nary(object)
        visit_edge(object, 'children')
      end
      alias visit_Arel_Nodes_And nary

      def visit_Hash(object)
        object.each do |key, value|
          process_node(value, Path.new([:[], key], key))
        end
      end

      def visit_Array(object)
        object.each_with_index do |child, index|
          process_node(child, Path.new([:[], index], index))
        end
      end

      def process_node(arel_node, path)
        parent = current_node
        new_path = parent.path + [path]

        node = Arel::Transformer::Node.new(
          arel_node,
          parent,
          new_path,
          parent.root_node,
        )

        parent.add(path, node)

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
