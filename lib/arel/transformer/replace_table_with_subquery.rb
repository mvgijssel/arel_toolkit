module Arel
  module Transformer
    class ReplaceTableWithSubquery
      attr_reader :subquery_for_table

      def initialize(subquery_for_table)
        @subquery_for_table = subquery_for_table
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
          schema_name: nil,
        ).each do |node|
          if (subquery = subquery_for_table.call(node.name.value))
            node.replace subquery.as(node.name.value)
          end
        end
      end
    end
  end
end
