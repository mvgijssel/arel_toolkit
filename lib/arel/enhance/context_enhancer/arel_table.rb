module Arel
  module Enhance
    module ContextEnhancer
      class ArelTable
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/AbcSize
        def self.call(node)
          context = node.context.merge!(
            range_variable: false, column_reference: false, alias: false,
          )
          parent_object = node.parent.object

          # Using Arel::Table as SELECT ... FROM <table>
          if parent_object.is_a?(Arel::Nodes::JoinSource)
            context[:range_variable] = true

          # NOTE: only applies to ActiveRecord generated Arel
          # which does not use Arel::Table#alias but Arel::TableAlias instead
          # Using Arel::Table as SELECT ... FROM <table> AS alias
          elsif parent_object.is_a?(Arel::Nodes::TableAlias) &&
                node.parent.parent.object.is_a?(Arel::Nodes::JoinSource)
            context[:range_variable] = true

          # Using Arel::Table as SELECT ... FROM [<table>]
          elsif parent_object.is_a?(Array) &&
                node.parent.parent.object.is_a?(Arel::Nodes::JoinSource)
            context[:range_variable] = true

          # NOTE: only applies to ActiveRecord generated Arel
          # which does not use Arel::Table#alias but Arel::TableAlias instead
          # Using Arel::Table as SELECT ... FROM [<table> AS alias]
          elsif parent_object.is_a?(Arel::Nodes::TableAlias) &&
                node.parent.parent.object.is_a?(Array) &&
                node.parent.parent.parent.object.is_a?(Arel::Nodes::JoinSource)
            context[:range_variable] = true

          elsif parent_object.is_a?(Arel::Nodes::TableAlias) &&
            node.parent.parent.object.is_a?(Arel::Attributes::Attribute)
            context[:column_reference] = true

          # Using Arel::Table as SELECT ... INNER JOIN <table> ON TRUE
          elsif parent_object.is_a?(Arel::Nodes::Join)
            context[:range_variable] = true

          elsif parent_object.is_a?(Arel::Nodes::TableAlias) &&
              node.parent.parent.object.is_a?(Arel::Nodes::Join)
            context[:range_variable] = true

          # Using Arel::Table as an attribute SELECT <table>.id ...
          elsif parent_object.is_a?(Arel::Attributes::Attribute)
            context[:column_reference] = true

          # Using Arel::Table in an INSERT INTO <table>
          elsif parent_object.is_a?(Arel::Nodes::InsertStatement)
            context[:range_variable] = true

          # Using Arel::Table in an UPDATE <table> ...
          elsif parent_object.is_a?(Arel::Nodes::UpdateStatement)
            context[:range_variable] = true

          # Arel::Table in UPDATE ... FROM [<table>]
          elsif parent_object.is_a?(Array) &&
                node.parent.parent.object.is_a?(Arel::Nodes::UpdateStatement)
            context[:range_variable] = true

          # Using Arel::Table in an DELETE FROM <table>
          elsif parent_object.is_a?(Arel::Nodes::DeleteStatement)
            context[:range_variable] = true

          # Arel::Table in DELETE ... USING [<table>]
          elsif parent_object.is_a?(Array) &&
                node.parent.parent.object.is_a?(Arel::Nodes::DeleteStatement)
            context[:range_variable] = true

          # Using Arel::Table as an "alias" for WITH <table> AS (SELECT 1) SELECT 1
          elsif parent_object.is_a?(Arel::Nodes::As) &&
                node.parent.parent.parent.object.is_a?(Arel::Nodes::With)
            context[:alias] = true

          # Using Arel::Table as an "alias" for WITH RECURSIVE <table> AS (SELECT 1) SELECT 1
          elsif parent_object.is_a?(Arel::Nodes::As) &&
                node.parent.parent.parent.object.is_a?(Arel::Nodes::WithRecursive)
            context[:alias] = true

          # Using Arel::Table as an "alias" for SELECT INTO <table> ...
          elsif parent_object.is_a?(Arel::Nodes::Into)
            context[:alias] = true

          else
            raise "Unknown AST location for table #{node.inspect}, #{node.root_node.to_sql}"
          end
        end
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
