module Arel
  module Transformer
    class ReplaceTableWithSubquery
      attr_reader :table_to_subquery_mapping

      def initialize(table_to_subquery_mapping)
        @table_to_subquery_mapping = table_to_subquery_mapping
      end

      def call(arel, next_middleware)
        tree = Arel.enhance(arel)
        update_arel_tables(tree)
        next_middleware.call tree
      end

      private

      def update_arel_tables(tree)
        tree.query(
          class: Arel::Table,
          context: { range_variable: true },
        ).each do |node|
          if (subquery = table_to_subquery_mapping[node.name.value])
            node.replace subquery.as(node.name.value)
          end
        end
      end
    end
  end
end
