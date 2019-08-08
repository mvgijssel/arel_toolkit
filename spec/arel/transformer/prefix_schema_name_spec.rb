describe Arel::Transformer::PrefixSchemaName do
  let(:next_middleware) { ->(new_arel) { new_arel } }

  context 'table' do
    it 'adds a schema to a table' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = 'SELECT "posts"."id" FROM "posts"'
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq 'SELECT "posts"."id" FROM "public"."posts"'
    end

    it 'does not add a schema when a schema is already defined' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = 'SELECT "posts"."id" FROM "some_schema"."posts"'
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq 'SELECT "posts"."id" FROM "some_schema"."posts"'
    end

    it 'allows to override the default schema' do
      transformer = Arel::Transformer::PrefixSchemaName.new(
        %w[secret public],
        'posts' => ['secret'],
      )
      sql = 'SELECT "posts"."id" FROM "posts" INNER JOIN "users" ON TRUE'
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq(
        'SELECT "posts"."id" FROM "secret"."posts" INNER JOIN "public"."users" ON \'t\'::bool',
      )
    end

    it 'uses the schema with the highest priority' do
      transformer = Arel::Transformer::PrefixSchemaName.new(
        %w[priority normal],
        'posts' => %w[normal priority],
        'comments' => ['normal'],
      )
      sql = 'SELECT * FROM "posts", "comments"'
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq 'SELECT * FROM "priority"."posts", "normal"."comments"'
    end

    it 'does not prefix a table in the pg_catalog namespace' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = 'SELECT * FROM "pg_class"'
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq sql
    end

    it 'fails for an unknown table' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = 'SELECT 1 FROM unknown_table'
      arel = Arel.sql_to_arel(sql)

      expect do
        transformer.call(arel.first, next_middleware).to_sql
      end.to raise_error(
        'Object `unknown_table` does not exist in the object_mapping and cannot be prefixed',
      )
    end
  end

  context 'regclass' do
    it 'prefixes a string casted as a regclass' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = "SELECT 'posts'::regclass"
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq "SELECT 'public.posts'::regclass"
    end

    it 'prefixes a quoted string casted as a regclass' do
      transformer = Arel::Transformer::PrefixSchemaName.new

      sql = %(SELECT '"posts"'::regclass)
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq %(SELECT 'public.\"posts\"'::regclass)
    end

    it 'does not update a string which already has a schema' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = "SELECT 'secret.posts'::regclass"
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq "SELECT 'secret.posts'::regclass"
    end

    it 'raises when the regclass consists of three or more parts' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = "SELECT 'something.secret.posts'::regclass"
      arel = Arel.sql_to_arel(sql)

      expect do
        transformer.call(arel.first, next_middleware).to_sql
      end.to raise_error(/Don't know how to handle `3` parts in/)
    end
  end

  context 'views' do
    it 'adds a schema to a view' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = 'SELECT "posts"."id" FROM "public_posts"'
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq 'SELECT "posts"."id" FROM "public"."public_posts"'
    end

    it 'adds a schema to a materialized view' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = 'SELECT "posts_count".* FROM "posts_count"'
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq 'SELECT "posts_count".* FROM "public"."posts_count"'
    end
  end

  context 'aggregate and function' do
    it 'adds a schema to an function' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = 'SELECT view_count()'
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq %(SELECT public.view_count())
    end

    it 'adds a schema to an aggregate' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = 'SELECT sum_view_count(id ORDER BY created_at)'
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq %(SELECT public.sum_view_count("id" ORDER BY "created_at"))
    end

    it 'works for an existing Arel aggregate node without a name' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = 'SELECT COUNT(*)'
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq %(SELECT COUNT(*))
    end

    it 'does not consider LEAST, GREATEST, NULLIF, COALESCE and EXISTS as a function' do
      transformer = Arel::Transformer::PrefixSchemaName.new
      sql = %(SELECT EXISTS(SELECT 1), LEAST(1, 2), GREATEST(1, 2), NULLIF(3, 3), COALESCE(NULL, 5))
      arel = Arel.sql_to_arel(sql)
      prefixed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(prefixed_sql).to eq(
        %(SELECT EXISTS (SELECT 1), LEAST(1, 2), GREATEST(1, 2), NULLIF(3, 3), COALESCE(NULL, 5)),
      )
    end
  end
end
