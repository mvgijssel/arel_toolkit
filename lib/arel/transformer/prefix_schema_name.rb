module Arel
  module Transformer
    class PrefixSchemaName
      attr_reader :schema_name

      def initialize(schema_name)
        @schema_name = schema_name
      end

      # https://github.com/mvgijssel/arel_toolkit/issues/110
      def call(arel, _context)
        tree = Arel.enhance(arel)

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
