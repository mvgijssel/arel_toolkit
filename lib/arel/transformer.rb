module Arel
  class Transformer
    # class Collector
    #   def initialize
    #     @tree = []
    #   end

    #   def value
    #     @tree
    #   end

    #   def <<(node)
    #     @tree << node
    #     self
    #   end
    # end

    class Visitor < Arel::Visitors::Dot
      def accept(object)
        root_node = Arel::Transformer::Node.new(
          object,
          nil,
          [],
        )

        with_node(root_node) do
          visit object
        end

        binding.pry

        root_node
      end

      def visit_edge(o, method)
        arel_node = o.send(method)
        parent = current_node
        path = parent.path + [method]

        node = Arel::Transformer::Node.new(
          arel_node,
          parent,
          path,
        )

        parent.add(method, node)

        with_node node do
          visit o.send(method)
        end
      end

      def visit(o)
        Arel::Visitors::Visitor.instance_method(:visit).bind(self).call(o)
      end

      def current_node
        @node_stack.last
      end
    end

    class Node
      attr_reader :node
      attr_reader :parent
      attr_reader :path
      attr_reader :fields
      attr_reader :children

      def initialize(node, parent, path)
        @node = node
        @parent = parent
        @path = path
        @fields = []
        @children = {}
      end

      def inspect
        recursive_inspect('')
      end

      def value
        @fields.first
      end

      def add(field, node)
        @children[field] = node
      end

      def [](key)
        @children.fetch(key)
      end

      protected

      def recursive_inspect(string, indent = 1)
        string << "<#{name_inspect} #{path.inspect}\n"
        string << "#{spacing(indent)}parent = #{parent && parent.name_inspect}"
        string << "\n" unless children.length.zero?
        children.each do |key, child|
          string << "#{spacing(indent)}#{key} =\n"
          string << spacing(indent + 1)
          child.recursive_inspect(string, indent + 2)
        end
        string << "\n" if children.length.zero? && value_inspect.present?
        string << "#{spacing(indent)}value = #{value_inspect}" unless value_inspect.nil?

        if children.length.zero?
          string << ">\n"
        else
          string << "#{spacing(indent - 1)}>\n"
        end
      end

      def name_inspect
        "Node(#{node.class.name})"
      end

      def value_inspect
        return if @fields.length.zero?
        value.nil? ? value.class : value
      end

      def spacing(indent)
        indent.times.reduce('') { |memo| memo << '  '; memo }
      end
    end

    def self.call(arel)
      Visitor.new.accept(arel)
    end
  end
end
