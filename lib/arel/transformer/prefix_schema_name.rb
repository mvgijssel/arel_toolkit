module Arel
  module Transformer
    class PrefixSchemaName
      PG_CATALOG = 'pg_catalog'.freeze
      DEFAULT_SCHEMA_PRIORITY = ['public', PG_CATALOG].freeze

      attr_reader :connection
      attr_reader :table_mapping
      attr_reader :schema_priority

      def initialize(
        connection,
        schema_priority = DEFAULT_SCHEMA_PRIORITY,
        override_table_mapping = {}
      )
        @connection = connection
        @schema_priority = schema_priority
        @table_mapping = database_table_mapping.merge(override_table_mapping)
      end

      # We don't need to prefix nodes with `pg_catalog`, because that's the default
      # even if the search_path does not include `pg_catalog`. Same for `information_schema`

      # https://github.com/mvgijssel/arel_toolkit/issues/110
      def call(arel, _context)
        tree = Arel.enhance(arel)
        update_tables(tree)
        update_typecasts(tree)
        tree.object
      end

      private

      def update_tables(tree)
        tree.query(
          class: Arel::Table,
          schema_name: nil,
          context: { range_variable: true },
        ).each do |node|
          schema_name = schema_name_from_table_name(node['name'].object.to_s)
          node['schema_name'].replace(schema_name)
        end
      end

      def update_typecasts(tree)
        tree.query(
          class: Arel::Nodes::TypeCast,
          type_name: 'regclass',
        ).each do |node|
          update_typecast_node(node)
        end
      end

      def update_typecast_node(node)
        table_name = table_name_from_arel_node(node['arg'].object)
        reference_parts = table_name.split('.')

        case reference_parts.length
        when 1
          schema_name = schema_name_from_table_name(table_name)
          reference_parts.unshift(schema_name)
          node['arg']['expr'].replace(reference_parts.join('.'))
        when 2
          node # Do nothing
        else
          raise "Don't know how to handle `#{reference_parts.length}` parts in " \
                "`#{reference_parts}` for sql `#{node.to_sql}`"
        end
      end

      def table_name_from_arel_node(arel_node)
        case arel_node
        when Arel::Nodes::Quoted
          arel_node.expr
        else
          raise "Unknown node `#{table_name}` for `#{node.inspect}`"
        end
      end

      def schema_name_from_table_name(table_name)
        possible_schemas = table_mapping[table_name]

        if possible_schemas.empty?
          raise "Table `#{table_name}` is an unknown table and cannot be prefixed"
        end

        schema_name = schema_priority.find do |possible_schema_name|
          possible_schemas.include?(possible_schema_name)
        end

        if schema_name.nil?
          raise "Could not find a schema name for table `#{table_name}`.\n" \
                "Current schema priority is `#{schema_priority}`.\n" \
                "Possible schemas are `#{possible_schemas}`."
        end

        return nil if schema_name == PG_CATALOG

        schema_name
      end

      def database_table_mapping
        mapping = Hash.new { |m, k| m[k] = [] }

        connection
          .execute('SELECT tablename, schemaname FROM pg_catalog.pg_tables')
          .each do |result|
          mapping[result.fetch('tablename').to_s] << result.fetch('schemaname').to_s
        end

        mapping
      end
    end
  end
end
