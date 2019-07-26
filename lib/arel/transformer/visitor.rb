module Arel
  module Transformer
    # rubocop:disable Naming/MethodName
    class Visitor < Arel::Visitors::Dot
      def accept(object)
        root_node = Arel::Transformer::Node.new(object)
        accept_with_root(object, root_node)
      end

      def accept_with_root(object, root_node)
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

      def visit_Hash(_object)
        raise 'Hash is not supported'
      end

      def visit_Array(object)
        object.each_with_index do |child, index|
          process_node(child, Arel::Transformer::PathNode.new([:[], index], index))
        end
      end

      def process_node(arel_node, path_node)
        node = Arel::Transformer::Node.new(arel_node)
        current_node.add(path_node, node)

        update_context(node)

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

      # Context we can add:
      # - this attribute is using in a projection, group, order, where
      # - this node belongs to this "group", like SELECT statement class
      #   - helps for subscriptions: "How are table A and B related?" -> "Give me references to table A" -> "Are there references here which point to B?"
      # - this Arel::Table node is a way of brining more data into the SQL query (FROM/JOIN) versus something else
      # - this Arel::Attributes::Attribute belongs to this reference (allows to re-link unqualified columns)
      # -
      def update_context(node)
        return unless node.object.is_a?(Arel::Table)

        context = node.context.merge!(range_variable: false, column_reference: false)

        # Using Arel::Table as SELECT ... FROM <table>
        if node.parent.object.is_a?(Arel::Nodes::JoinSource)
          context[:range_variable] = true
        # Using Arel::Table as SELECT ... FROM [<table>]
        elsif node.parent.object.is_a?(Array) && node.parent.parent.object.is_a?(Arel::Nodes::JoinSource)
          context[:range_variable] = true
        # Using Arel::Table as SELECT ... INNER JOIN <table> ON TRUE
        elsif node.parent.object.is_a?(Arel::Nodes::Join)
          context[:range_variable] = true

        # Using Arel::Table as an attribute SELECT <table>.id ...
        elsif node.parent.object.is_a?(Arel::Attributes::Attribute)
          context[:column_reference] = true

        # Using Arel::Table in an INSERT INTO <table>
        elsif node.parent.object.is_a?(Arel::Nodes::InsertStatement)
          context[:range_variable] = true

        # Using Arel::Table in an UPDATE <table> ...
        elsif node.parent.object.is_a?(Arel::Nodes::UpdateStatement)
          context[:range_variable] = true
        elsif node.parent.object.is_a?(Array) && node.parent.parent.object.is_a?(Arel::Nodes::UpdateStatement)
          # Arel::Table in UPDATE ... FROM [<table>]
          context[:range_variable] = true

        # Using Arel::Table in an DELETE FROM <table>
        elsif node.parent.object.is_a?(Arel::Nodes::DeleteStatement)
          context[:range_variable] = true
        elsif node.parent.object.is_a?(Array) && node.parent.parent.object.is_a?(Arel::Nodes::DeleteStatement)
          # Arel::Table in DELETE ... USING [<table>]
          context[:range_variable] = true

        # Using Arel::Table as an "alias" for WITH <table> AS (SELECT 1) SELECT 1
        elsif node.parent.object.is_a?(Arel::Nodes::As) && node.parent.parent.parent.object.is_a?(Arel::Nodes::With)
          context[:alias] = true
        # Using Arel::Table as an "alias" for WITH RECURSIVE <table> AS (SELECT 1) SELECT 1
        elsif node.parent.object.is_a?(Arel::Nodes::As) && node.parent.parent.parent.object.is_a?(Arel::Nodes::WithRecursive)
          context[:alias] = true
        # Using Arel::Table as an "alias" for SELECT INTO <table> ...
        elsif node.parent.object.is_a?(Arel::Nodes::Into)
          context[:alias] = true

        else
          raise "Unknown location for table #{node.inspect}, #{sql}"
        end
      end
    end
    # rubocop:enable Naming/MethodName
  end
end
