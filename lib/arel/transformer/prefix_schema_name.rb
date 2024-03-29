module Arel
  module Transformer
    class PrefixSchemaName
      PG_CATALOG = 'pg_catalog'.freeze
      DEFAULT_SCHEMA_PRIORITY = ['public', PG_CATALOG].freeze

      attr_reader :object_mapping, :schema_priority

      def initialize(
        schema_priority = DEFAULT_SCHEMA_PRIORITY,
        override_object_mapping = {}
      )
        @schema_priority = schema_priority
        @object_mapping = database_object_mapping.merge(override_object_mapping)
      end

      def call(arel, next_middleware)
        tree = Arel.enhance(arel)
        update_arel_tables(tree)
        update_typecasts(tree)
        update_functions(tree)

        next_middleware.call tree
      end

      private

      def update_arel_tables(tree)
        tree.query(
          class: Arel::Table,
          schema_name: nil,
          context: { range_variable: true },
        ).each do |node|
          schema_name = schema_name_from_object_name(node['name'].object.to_s)
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
          schema_name = schema_name_from_object_name(table_name)
          reference_parts.unshift(schema_name)
          node['arg']['expr'].replace(reference_parts.join('.'))
        when 2
          node # Do nothing
        else
          raise "Don't know how to handle `#{reference_parts.length}` parts in " \
                "`#{reference_parts}` for sql `#{node.to_sql}`"
        end
      end

      def update_functions(tree)
        tree.query(
          class: Arel::Enhance::QueryMethods.in_ancestors?(Arel::Nodes::Function),
          schema_name: nil,
        ).each do |node|
          update_function_node(node)
        end
      end

      def update_function_node(node)
        object_name = if node.object.is_a?(Arel::Nodes::NamedFunction)
                        node['name'].object.downcase
                      else
                        node.object.class.to_s.demodulize.underscore
                      end

        schema_name = schema_name_from_object_name(object_name)
        node['schema_name'].replace(schema_name)
      end

      def table_name_from_arel_node(arel_node)
        case arel_node
        when Arel::Nodes::Quoted
          arel_node.expr
        else
          raise "Unknown node `#{table_name}` for `#{node.inspect}`"
        end
      end

      def schema_name_from_object_name(table_name)
        table_name = unquote_string(table_name)
        possible_schemas = object_mapping[table_name]

        if possible_schemas.nil?
          raise "Object `#{table_name}` does not exist in the object_mapping and cannot be prefixed"
        end

        schema_name = schema_priority.find do |possible_schema_name|
          possible_schemas.include?(possible_schema_name)
        end

        if schema_name.nil?
          raise "Could not find a schema name for table `#{table_name}`.\n" \
                "Current schema priority is `#{schema_priority}`.\n" \
                "Possible schemas are `#{possible_schemas}`."
        end

        # We don't need to prefix nodes with `pg_catalog`, because that's the default
        # even if the search_path does not include `pg_catalog`.
        return nil if schema_name == PG_CATALOG

        schema_name
      end

      # https://www.rubydoc.info/github/rubyworks/facets/String:unquote
      def unquote_string(string)
        s = string.dup

        case string[0, 1]
        when "'", '"', '`'
          s[0] = ''
        end

        case string[-1, 1]
        when "'", '"', '`'
          s[-1] = ''
        end

        s
      end

      def database_object_mapping
        mapping = {}
        update_mapping mapping, database_tables
        update_mapping mapping, database_views
        update_mapping mapping, database_materialized_views
        update_mapping mapping, database_functions

        mapping
      end

      def update_mapping(mapping, objects)
        objects.each do |object|
          name = object.fetch('object_name').to_s.downcase
          mapping[name] ||= []
          mapping[name] << object.fetch('schema_name').to_s
        end
      end

      def database_tables
        connection.execute(
          'SELECT tablename AS object_name, schemaname AS schema_name FROM pg_tables',
        )
      end

      def database_views
        connection.execute(
          'SELECT viewname AS object_name, schemaname AS schema_name FROM pg_views',
        )
      end

      def database_materialized_views
        connection.execute(
          'SELECT matviewname AS object_name, schemaname AS schema_name FROM pg_matviews',
        )
      end

      def database_functions
        connection.execute(
          'SELECT pg_proc.proname AS object_name, pg_namespace.nspname AS schema_name ' \
          'FROM pg_proc INNER JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid',
        )
      end

      def connection
        Arel::Table.engine.connection
      end
    end
  end
end
