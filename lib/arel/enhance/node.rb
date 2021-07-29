module Arel
  module Enhance
    class Node
      attr_reader :local_path
      attr_reader :object
      attr_reader :parent
      attr_reader :root_node

      def initialize(object)
        @object = object
        @root_node = self
        @dirty = false
      end

      def inspect
        recursive_inspect('')
      end

      def value
        return unless value?

        fields.first
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

      def replace(new_arel_node)
        mutate(new_arel_node)
      end

      def add(path_node, node)
        node.local_path = path_node
        node.parent = self
        node.root_node = root_node
        children[path_node.value.to_s] = node
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

      def to_sql_and_binds(engine = Table.engine)
        object.to_sql_and_binds(engine)
      end

      def method_missing(name, *args, &block)
        child = children[name.to_s]
        return super if child.nil?

        child
      end

      def respond_to_missing?(method, include_private = false)
        child = children[method.to_s]
        child.present? || super
      end

      def [](key)
        children.fetch(key.to_s)
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

      def full_path
        the_path = [local_path]
        current_parent = parent

        while current_parent
          the_path.unshift current_parent.local_path
          current_parent = current_parent.parent
        end

        the_path.compact
      end

      def children
        @children ||= {}
      end

      def fields
        @fields ||= []
      end

      def context
        @context ||= {}
      end

      protected

      attr_writer :local_path
      attr_writer :parent
      attr_writer :root_node

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def recursive_inspect(string, indent = 1)
        string << "<#{inspect_name} #{full_path.inspect}\n"
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
        self.object = new_object

        recursive_update_object(new_object)
      end

      def recursive_update_object(arel_tree)
        children.each_value do |child|
          tree_child = arel_tree.send(*child.local_path.method)
          child.object = tree_child
          child.recursive_update_object(tree_child)
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
        new_arel_node = new_node.is_a?(Arel::Enhance::Node) ? new_node.object : new_node
        new_arel_node = [] if remove && object.is_a?(Array)

        if parent_object.respond_to?("#{local_path.value}=")
          parent_object.send("#{local_path.value}=", new_arel_node)

        elsif parent_object.instance_values.key?(local_path.value)
          parent_object.instance_variable_set("@#{local_path.value}", new_arel_node)

        elsif local_path.arguments? && parent_object.respond_to?(local_path.method[0])
          if remove
            parent_object.delete_at(local_path.value)

          else
            parent_object[local_path.value] = new_arel_node
          end
        else
          raise "Don't know how to replace `#{local_path.value}` in #{parent_object.inspect}"
        end

        if new_node.is_a?(Arel::Enhance::Node)
          parent.add(local_path, new_node)
          parent[local_path.value]
        else
          new_parent_tree = Visitor.new.accept_with_root(parent_object, parent)
          parent.parent.add(parent.local_path, new_parent_tree)
          new_parent_tree[local_path.value]
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize
    end
  end
end
