module Arel
  class Transformer
    # rubocop:disable Naming/MethodName
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

        root_node
      end

      private

      def visit_edge(object, method)
        arel_node = object.send(method)

        process_node(arel_node, method)
      end

      def nary(object)
        visit_edge(object, 'children')
      end
      alias visit_Arel_Nodes_And nary

      def visit_Hash(object)
        object.each do |key, value|
          process_node(value, key)
        end
      end

      def visit_Array(object)
        object.each_with_index do |child, index|
          process_node(child, index)
        end
      end

      def process_node(arel_node, method)
        parent = current_node
        path = parent.path + [method]

        node = Arel::Transformer::Node.new(
          arel_node,
          parent,
          path,
        )

        parent.add(method, node)

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

    class Node
      attr_reader :object
      attr_reader :parent
      attr_reader :path
      attr_reader :fields
      attr_reader :children

      def initialize(object, parent, path)
        @object = object
        @parent = parent
        @path = path
        @fields = []
        @children = {}
      end

      def inspect
        recursive_inspect('')
      end

      def value
        return unless value?

        @fields.first
      end

      def value?
        children.empty?
      end

      def add(field, object)
        @children[field] = object
      end

      def to_sql(engine = Table.engine)
        return nil if children.empty?

        collector = Arel::Collectors::SQLString.new
        collector = engine.connection.visitor.accept object, collector
        collector.value
      end

      def [](key)
        @children.fetch(key)
      end

      protected

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def recursive_inspect(string, indent = 1)
        string << "<#{inspect_name} #{path.inspect}\n"
        string << "#{spacing(indent)}sql = #{to_sql}\n" unless to_sql.nil?
        string << "#{spacing(indent)}parent = #{parent.nil? ? nil.inspect : parent.inspect_name}"
        string << "\n" unless children.length.zero?
        children.each do |key, child|
          string << "#{spacing(indent)}#{key} =\n"
          string << spacing(indent + 1)
          child.recursive_inspect(string, indent + 2)
        end
        string << "\n" if children.length.zero? && value?
        string << "#{spacing(indent)}value = #{value.inspect}" if value?

        string << if children.length.zero?
                    ">\n"
                  else
                    "#{spacing(indent - 1)}>\n"
                  end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def inspect_name
        "Node(#{object.class.name})"
      end

      def spacing(indent)
        indent.times.reduce('') do |memo|
          memo << '  '
          memo
        end
      end
    end

    def self.call(arel)
      Visitor.new.accept(arel)
    end
  end
end
