module Arel
  module Transformer
    class AddSchemaToTable
      attr_reader :schema_name

      def initialize(schema_name)
        @schema_name = schema_name
      end

      def call(arel, _context)
        tree = Arel.transformer(arel)

        tree.query(
          class: Arel::Table,
          schema_name: nil,
          context: { range_variable: true },
        ).each do |node|
          node['schema_name'].replace(schema_name)
        end

        tree.object
      end
    end
  end
end
