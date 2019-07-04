module Arel
  module Transformer
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
  end
end
