module Arel
  module Transformer
    class Node
      attr_reader :object
      attr_reader :parent
      attr_reader :path
      attr_reader :fields
      attr_reader :children
      attr_reader :root_node

      def initialize(object, parent, path, root_node)
        @object = object
        @parent = parent
        @path = path
        @root_node = root_node || self
        @fields = []
        @children = {}
        @dirty = false
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

      def dirty?
        root_node.instance_values.fetch('dirty')
      end

      def to_a
        children_array = children.map do |_name, child|
          child.to_a
        end

        [self].concat children_array.flatten
      end

      def remove
        replace(nil, remove: true)
      end

      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      def replace(new_node, remove: false)
        root_node.mark_as_dirty

        parent_object = parent.object
        new_node = [] if remove && object.is_a?(Array)

        if parent_object.respond_to?("#{current_path.inspect}=")
          parent_object.send("#{current_path.inspect}=", new_node)
          new_tree = Visitor.new.accept(new_node, parent, current_path)
          parent.add(current_path, new_tree)

        elsif parent_object.instance_values.key?(current_path.inspect)
          parent_object.instance_variable_set("@#{current_path.inspect}")
          new_tree = Visitor.new.accept(new_node, parent, current_path)
          parent.add(current_path, new_tree)

        elsif parent_object.is_a?(Array) &&
              current_path.inspect.is_a?(Integer) &&
              current_path.inspect < parent_object.length

          if remove
            parent_object.delete_at(current_path.inspect)
            parent.children.delete(current_path.inspect)

          else
            parent_object[current_path.inspect] = new_node
            new_tree = Visitor.new.accept(new_node, parent, current_path)
            parent.add(current_path, new_tree)
          end
        else
          raise "Don't know how to replace `#{current_path.inspect}` in #{parent_object.inspect}"
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize

      def current_path
        path.last
      end

      def add(field, object)
        @children[field.inspect] = object
      end

      def to_sql(engine = Table.engine)
        return nil if children.empty?

        target_object = object.is_a?(Arel::SelectManager) ? object.ast : object
        collector = Arel::Collectors::SQLString.new
        collector = engine.connection.visitor.accept target_object, collector
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

      def deep_copy_object
        # https://github.com/mvgijssel/arel_toolkit/issues/97
        new_object = Marshal.load(Marshal.dump(object))
        recursive_replace_object(new_object)
      end

      def recursive_replace_object(new_object)
        @object = new_object

        children.each_value do |child|
          child.recursive_replace_object(new_object.send(*child.current_path.method))
        end
      end

      def mark_as_dirty
        return if dirty?

        @dirty = true
        deep_copy_object
      end
    end
  end
end
