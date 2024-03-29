require_relative './context_enhancer/arel_table'

module Arel
  module Enhance
    # rubocop:disable Naming/MethodName
    class Visitor < Arel::Visitors::Dot
      DEFAULT_CONTEXT_ENHANCERS = {
        Arel::Table => Arel::Enhance::ContextEnhancer::ArelTable,
      }.freeze

      attr_reader :context_enhancers

      def accept(object, context_enhancers = DEFAULT_CONTEXT_ENHANCERS)
        @context_enhancers = context_enhancers

        root_node = Arel::Enhance::Node.new(object)
        accept_with_root(object, root_node, context_enhancers)
      end

      def accept_with_root(object, root_node, context_enhancers = DEFAULT_CONTEXT_ENHANCERS)
        @context_enhancers = context_enhancers

        with_node(root_node) do
          visit object
        end

        root_node
      end

      private

      def visit_edge(object, method)
        arel_node = object.send(method)

        process_node(arel_node, Arel::Enhance::PathNode.new(method, method))
      end

      def nary(object)
        visit_edge(object, 'children')
      end
      alias visit_Arel_Nodes_And nary

      def visit_Hash(object)
        object.each do |key, child|
          process_node(child, Arel::Enhance::PathNode.new([:[], key], key))
        end
      end

      def visit_Array(object)
        object.each_with_index do |child, index|
          process_node(child, Arel::Enhance::PathNode.new([:[], index], index))
        end
      end

      def process_node(arel_node, path_node)
        node = Arel::Enhance::Node.new(arel_node)
        current_node.add(path_node, node)

        update_context(node)

        with_node node do
          visit arel_node
        end
      end

      # rubocop:disable Metrics/AbcSize
      # arel/lib/arel/visitors/visitor.rb:29
      def visit(object)
        dispatch_method = dispatch[object.class]
        send dispatch_method, object
      rescue NoMethodError => e
        raise e if respond_to?(dispatch_method, true)

        superklass = object.class.ancestors.find do |klass|
          respond_to?(dispatch[klass], true)
        end
        raise(TypeError, "Cannot visit #{object.class}") unless superklass

        dispatch[object.class] = dispatch[superklass]
        retry
      end
      # rubocop:enable Metrics/AbcSize

      def current_node
        @node_stack.last
      end

      def update_context(node)
        enhancer = context_enhancers[node.object.class]
        return if enhancer.nil?

        enhancer.call(node)
      end
    end
    # rubocop:enable Naming/MethodName
  end
end
