module Arel
  module Enhance
    class Node
      attr_reader :object
      attr_reader :parent
      attr_reader :path
      attr_reader :fields
      attr_reader :children
      attr_reader :root_node
      attr_reader :context

      def initialize(object)
        @object = object
        @path = Path.new
        @root_node = self
        @fields = []
        @children = {}
        @dirty = false
        @context = {}
      end

      def inspect
        recursive_inspect('')
      end

      def value
        return unless value?

        @fields.first
      end

      def each(&block)
        return enum_for(:each) unless block_given?

        yield self

        children.each_value do |child|
          child.each(&block)
        end
      end

      def value?
        children.empty?
      end

      def dirty?
        root_node.instance_values.fetch('dirty')
      end

      def remove
        mutate(nil, remove: true)
      end

      def replace(new_node)
        mutate(new_node)
      end

      def add(path_node, node)
        node.path = path.append(path_node)
        node.parent = self
        node.root_node = root_node
        @children[path_node.value.to_s] = node
      end

      def to_sql(engine = Table.engine)
        return nil if children.empty?

        if object.respond_to?(:to_sql)
          object.to_sql(engine)
        else
          collector = Arel::Collectors::SQLString.new
          collector = engine.connection.visitor.accept object, collector
          collector.value
        end
      end

      def method_missing(name, *args, &block)
        child = @children[name.to_s]
        return super if child.nil?

        child
      end

      def respond_to_missing?(method, include_private = false)
        child = @children[name.to_s]
        child.present? || super
      end

      def [](key)
        @children.fetch(key.to_s)
      end

      def child_at_path(path_items)
        selected_node = self
        path_items.each do |path_item|
          selected_node = selected_node[path_item]
          return nil if selected_node.nil?
        end
        selected_node
      end

      def query(**kwargs)
        Arel::Enhance::Query.call(self, kwargs)
      end

      protected

      attr_writer :path
      attr_writer :parent
      attr_writer :root_node

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity

      # TODO: cool if we can do relative paths in the inspects
      # to the node calling the inspect method
      # Meaning calculating paths at runtime?
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
      attr_writer :object

      def inspect_name
        "Node(#{object.class.name})"
      end

      def spacing(indent)
        indent.times.reduce('') do |memo|
          memo << '  '
          memo
        end
      end

      def deep_copy_object
        # https://github.com/mvgijssel/arel_toolkit/issues/97
        new_object = Marshal.load(Marshal.dump(object))

        each do |node|
          selected_object = node.path.dig_send(new_object)
          node.object = selected_object
        end
      end

      def mark_as_dirty
        return if dirty?

        @dirty = true
        deep_copy_object
      end

      private

      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      def mutate(new_node, remove: false)
        root_node.mark_as_dirty

        parent_object = parent.object
        new_node = [] if remove && object.is_a?(Array)

        if parent_object.respond_to?("#{path.current.value}=")
          parent_object.send("#{path.current.value}=", new_node)

        elsif parent_object.instance_values.key?(path.current.value)
          parent_object.instance_variable_set("@#{path.current.value}", new_node)

        elsif path.current.arguments? && parent_object.respond_to?(path.current.method[0])
          if remove
            parent_object.delete_at(path.current.value)

          else
            parent_object[path.current.value] = new_node
          end
        else
          raise "Don't know how to replace `#{path.current.value}` in #{parent_object.inspect}"
        end

        new_parent_tree = Visitor.new.accept_with_root(parent_object, parent)
        parent.parent.add(parent.path.current, new_parent_tree)
        new_parent_tree[path.current.value]
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize
    end
  end
end
