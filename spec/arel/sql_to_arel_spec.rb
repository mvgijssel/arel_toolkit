describe 'Arel.sql_to_arel' do
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/AbcSize
  def ast_contains_constant(tree, constant)
    case tree
    when Array
      tree.any? do |child|
        ast_contains_constant(child, constant)
      end
    when Hash
      tree.any? do |key, value|
        next true if key.to_s == constant.to_s

        ast_contains_constant(value, constant)
      end
    when String
      tree.to_s == constant.to_s
    when Integer
      tree.to_s == constant.to_s
    when TrueClass
      tree.to_s == constant.to_s
    when FalseClass
      tree.to_s == constant.to_s
    when NilClass
      tree.to_s == constant.to_s
    else
      raise '?'
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  around(:example) do |example|
    old_visitor = Arel::Table.engine.connection.visitor
    Arel::Table.engine.connection.visitor = Arel::Visitors::PostgreSQL.new(
      Arel::Table.engine.connection,
    )
    example.call
    Arel::Table.engine.connection.visitor = old_visitor
  end

  define :ast_contains do |expected|
    match do |pg_query_tree|
      ast_contains_constant(pg_query_tree, expected)
    end

    failure_message do |pg_query_tree|
      "expected that #{pg_query_tree} would contain `#{expected}`"
    end
  end

  shared_examples 'all' do |sql, pg_query_node|
    it "expects `#{pg_query_node}` to appear in the ast" do
      tree = PgQuery.parse(sql).tree
      expect(tree).to ast_contains(Object.const_get(pg_query_node))
    end

    it "expects the sql `#{sql}` to parse the same" do
      parsed_sql = Arel.sql_to_arel(sql).to_sql
      expect(parsed_sql).to eq sql
    end
  end

  shared_examples 'pg' do |sql, pg_query_node|
    it "expects `#{pg_query_node}` to appear in the ast" do
      tree = PgQuery.parse(sql).tree
      expect(tree).to ast_contains(Object.const_get(pg_query_node))
    end
  end

  visit 'all', 'SELECT ARRAY[1, 2, 3]', 'PgQuery::A_ARRAY_EXPR'
  visit 'all', 'SELECT 1', 'PgQuery::A_CONST'
  visit 'all',
        'SELECT ' \
        '1 = 2, ' \
        "3 = ANY('{4,5}'), 'a' = ANY($1), " \
        "6 = ALL('{7,8}'), 'b' = ALL($2), " \
        '"c" IS DISTINCT FROM "d", 7 IS NOT DISTINCT FROM \'d\', ' \
        "NULLIF(9, 10), NULLIF('e', 'f'), " \
        '' \
        "11 IN (12), 'a' NOT IN ('b'), " \
        "'ghi' NOT LIKE 'gh%', 'ghi' LIKE '_h_' ESCAPE 'i', " \
        "'jkl' NOT ILIKE 'jk%', 'jkl' ILIKE '_k_' ESCAPE 'k', " \
        "'mn' SIMILAR TO '(m|o)', 'mn' NOT SIMILAR TO '_h{1}%' ESCAPE '_', " \
        '14 BETWEEN 13 AND 15, ' \
        '16 NOT BETWEEN 17 AND 18, ' \
        '20 BETWEEN SYMMETRIC 21 AND 19, ' \
        '22 NOT BETWEEN SYMMETRIC 24 AND 23',
        'PgQuery::A_EXPR'
  visit 'all', 'SELECT field[1]', 'PgQuery::A_INDICES'
  visit 'all', 'SELECT something[1]', 'PgQuery::A_INDIRECTION'
  visit 'all', 'SELECT *', 'PgQuery::A_STAR'
  visit 'pg', 'GRANT INSERT, UPDATE ON mytable TO myuser', 'PgQuery::ACCESS_PRIV'
  visit 'all', 'SELECT 1 FROM "a" "b"', 'PgQuery::ALIAS'
  visit 'pg', 'ALTER TABLE stuff ADD COLUMN address text', 'PgQuery::ALTER_TABLE_CMD'
  visit 'pg', 'ALTER TABLE stuff ADD COLUMN address text', 'PgQuery::ALTER_TABLE_STMT'
  visit 'all', "SELECT B'0101'", 'PgQuery::BIT_STRING'
  visit 'all', 'SELECT 1 WHERE 1 AND 2', 'PgQuery::BOOL_EXPR'
  visit 'all', 'SELECT 1 WHERE 1 IS TRUE', 'PgQuery::BOOLEAN_TEST'
  visit 'all',
        'SELECT CASE WHEN "a" = "b" THEN 2 = 2 WHEN "a" THEN \'b\' ELSE 1 = 1 END',
        'PgQuery::CASE_EXPR'
  visit 'all',
        "SELECT CASE \"field\" WHEN \"a\" THEN 1 WHEN 'b' THEN 0 ELSE 2 END",
        'PgQuery::CASE_WHEN'
  visit 'pg', 'CHECKPOINT', 'PgQuery::CHECK_POINT_STMT'
  visit 'pg', 'CLOSE cursor;', 'PgQuery::CLOSE_PORTAL_STMT'
  visit 'all', "SELECT COALESCE(\"a\", NULL, 2, 'b')", 'PgQuery::COALESCE_EXPR'
  # visit 'pg', 'SELECT a COLLATE "C"', 'PgQuery::COLLATE_CLAUSE'
  visit 'pg', 'CREATE TABLE a (column_def_column text)', 'PgQuery::COLUMN_DEF'
  visit 'all', 'SELECT "id"', 'PgQuery::COLUMN_REF'
  visit 'all',
        'WITH "a" AS (SELECT 1) '\
        'SELECT * FROM (WITH RECURSIVE "c" AS (SELECT 1) SELECT * FROM "c") "d"',
        'PgQuery::COMMON_TABLE_EXPR'
  visit 'pg', 'CREATE TABLE a (b integer NOT NULL)', 'PgQuery::CONSTRAINT'
  visit 'pg', 'COPY reports TO STDOUT', 'PgQuery::COPY_STMT'
  visit 'pg',
        "CREATE FUNCTION a(integer) RETURNS integer AS 'SELECT $1;' LANGUAGE SQL;",
        'PgQuery::CREATE_FUNCTION_STMT'
  visit 'pg', 'CREATE SCHEMA secure', 'PgQuery::CREATE_SCHEMA_STMT'
  visit 'pg', 'CREATE TABLE a (b integer)', 'PgQuery::CREATE_STMT'
  visit 'pg', 'CREATE TABLE a AS (SELECT * FROM reports)', 'PgQuery::CREATE_TABLE_AS_STMT'
  visit 'pg', 'CREATE UNLOGGED TABLE a AS (SELECT * FROM reports)', 'PgQuery::CREATE_TABLE_AS_STMT'
  visit 'pg', 'CREATE TEMPORARY TABLE a AS (SELECT * FROM reports)', 'PgQuery::CREATE_TABLE_AS_STMT'
  visit 'pg',
        'CREATE TRIGGER a AFTER INSERT ON b FOR EACH ROW EXECUTE PROCEDURE b()',
        'PgQuery::CREATE_TRIG_STMT'
  visit 'pg', 'DEALLOCATE some_prepared_statement', 'PgQuery::DEALLOCATE_STMT'
  visit 'pg', 'DECLARE a CURSOR FOR SELECT 1', 'PgQuery::DECLARE_CURSOR_STMT'
  visit 'pg', 'DO $$ a $$', 'PgQuery::DEF_ELEM'
  visit 'all',
        'WITH "some_delete_query" AS (SELECT 1 AS some_column) ' \
        'DELETE FROM ONLY "a" "some_table" ' \
        'USING "other_table", "another_table" ' \
        'WHERE "other_table"."other_column" = 1.0 ' \
        'RETURNING *, "some_delete_query"."some_column"',
        'PgQuery::DELETE_STMT'
  visit 'all', 'DELETE FROM "a" WHERE CURRENT OF some_cursor_name', 'PgQuery::DELETE_STMT'
  # visit 'pg', 'DISCARD ALL', 'PgQuery::DISCARD_STMT'
  visit 'pg', 'DO $$ a $$', 'PgQuery::DO_STMT'
  visit 'pg', 'DROP TABLE some_tablr', 'PgQuery::DROP_STMT'
  visit 'pg', 'EXECUTE some_prepared_statement', 'PgQuery::EXECUTE_STMT'
  visit 'pg', 'EXPLAIN SELECT 1', 'PgQuery::EXPLAIN_STMT'
  visit 'pg', 'FETCH some_cursor', 'PgQuery::FETCH_STMT'
  visit 'all', 'SELECT 1.9', 'PgQuery::FLOAT'
  visit 'all',
        'SELECT ' \
        'SUM("a") AS some_a_sum, ' \
        'RANK("b"), ' \
        'COUNT("c"), ' \
        'GENERATE_SERIES(1, 5), ' \
        'MAX("d"), ' \
        'MIN("e"), ' \
        'AVG("f"), ' \
        'SUM("a" ORDER BY "id", "a" DESC), ' \
        'SUM("a") FILTER(WHERE "a" = 1), ' \
        'SUM("a") WITHIN GROUP (ORDER BY "a"), ' \
        'mleast(VARIADIC ARRAY[10, -1, 5, 4.4]), ' \
        'COUNT(DISTINCT "some_column"), ' \
        'some_function("a", \'b\', 1)',
        'PgQuery::FUNC_CALL'
  visit 'pg',
        "CREATE FUNCTION a(integer) RETURNS integer AS 'SELECT $1;' LANGUAGE SQL;",
        'PgQuery::FUNCTION_PARAMETER'
  visit 'pg', 'GRANT some_admins TO some_users', 'PgQuery::GRANT_ROLE_STMT'
  visit 'pg', 'GRANT SELECT ON some_table TO some_users', 'PgQuery::GRANT_STMT'
  visit 'pg', 'CREATE INDEX some_index ON some_table USING GIN (some_column)', 'PgQuery::INDEX_ELEM'
  visit 'pg', 'CREATE INDEX some_index ON some_table (some_column)', 'PgQuery::INDEX_STMT'
  visit 'all',
        'INSERT INTO "t" ("a", "b", "c", "d") ' \
        'OVERRIDING SYSTEM VALUE ' \
        'VALUES (1, "a", \'c\', \'t\'::bool, 2.0, $1) ' \
        'RETURNING *, "some_column" AS some_column_alias',
        'PgQuery::INSERT_STMT'
  visit 'all',
        'WITH RECURSIVE "a" AS (SELECT "some_table"."a" FROM "some_table") ' \
        'INSERT INTO "t" OVERRIDING USER VALUE VALUES (1)',
        'PgQuery::INSERT_STMT'
  visit 'all', 'INSERT INTO "t" VALUES (1)', 'PgQuery::INSERT_STMT'
  visit 'all', 'INSERT INTO "t" DEFAULT VALUES', 'PgQuery::INSERT_STMT'
  visit 'all', 'INSERT INTO "t" VALUES (1) ON CONFLICT DO NOTHING', 'PgQuery::INSERT_STMT'
  visit 'all',
        'INSERT INTO "t" VALUES (1) ON CONFLICT DO UPDATE ' \
        'SET "a" = 1, "b" = DEFAULT, "c" = (SELECT 1) ' \
        'WHERE 2 = 3',
        'PgQuery::INSERT_STMT'
  visit 'all',
        'INSERT INTO "t" VALUES (1) ON CONFLICT ON CONSTRAINT constaint_name DO UPDATE SET "a" = 1',
        'PgQuery::INSERT_STMT'
  visit 'all',
        'INSERT INTO "t" VALUES (1) ON CONFLICT (a, b) DO UPDATE SET "a" = 1',
        'PgQuery::INSERT_STMT'
  # visit 'pg', '???', 'PgQuery::INT_LIST'
  visit 'all', 'SELECT 1', 'PgQuery::INTEGER'
  visit 'pg', 'SELECT INTO some_table FROM new_table', 'PgQuery::INTO_CLAUSE'
  visit 'all',
        'SELECT * FROM "a" ' \
        'INNER JOIN "b" ON 1 = 1 ' \
        'LEFT OUTER JOIN "c" ON 1 = 1 ' \
        'FULL OUTER JOIN "d" ON 1 = 1 ' \
        'RIGHT OUTER JOIN "e" ON 1 = 1 ' \
        'CROSS JOIN "f" ' \
        'NATURAL JOIN "g"',
        'PgQuery::JOIN_EXPR'
  visit 'pg', 'LOCK TABLE some_table IN SHARE MODE;', 'PgQuery::LOCK_STMT'
  visit 'all', 'SELECT 1 FOR UPDATE NOWAIT', 'PgQuery::LOCKING_CLAUSE'
  visit 'all', 'SELECT 1 FOR NO KEY UPDATE NOWAIT', 'PgQuery::LOCKING_CLAUSE'
  visit 'all', 'SELECT 1 FOR SHARE SKIP LOCKED', 'PgQuery::LOCKING_CLAUSE'
  visit 'all', 'SELECT 1 FOR KEY SHARE', 'PgQuery::LOCKING_CLAUSE'
  visit 'all', 'SELECT NULL', 'PgQuery::NULL'
  visit 'all', 'SELECT "a" IS NULL AND \'b\' IS NOT NULL', 'PgQuery::NULL_TEST'
  # visit 'pg', '???', 'PgQuery::OID_LIST'
  visit 'all', 'SELECT $1', 'PgQuery::PARAM_REF'
  visit 'pg', 'PREPARE some_plan (integer) AS (SELECT $1)', 'PgQuery::PREPARE_STMT'
  visit 'all',
        'SELECT * FROM LATERAL ROWS FROM (a(), b()) WITH ORDINALITY',
        'PgQuery::RANGE_FUNCTION'
  visit 'all',
        'SELECT * FROM (SELECT \'b\') "a" INNER JOIN LATERAL (SELECT 1) "b" ON \'t\'::bool',
        'PgQuery::RANGE_SUBSELECT'
  visit 'all', 'SELECT 1 FROM "public"."table_is_range_var" "alias", ONLY "b"', 'PgQuery::RANGE_VAR'
  visit 'all', 'SELECT 1', 'PgQuery::RAW_STMT'
  visit 'pg', 'REFRESH MATERIALIZED VIEW view WITH NO DATA', 'PgQuery::REFRESH_MAT_VIEW_STMT'
  visit 'pg', 'ALTER TABLE some_table RENAME COLUMN some_column TO a', 'PgQuery::RENAME_STMT'
  visit 'all', 'SELECT 1', 'PgQuery::RES_TARGET'
  visit 'pg', 'ALTER GROUP some_role ADD USER some_user', 'PgQuery::ROLE_SPEC'
  visit 'all', "SELECT ROW(1, 2.5, 'a')", 'PgQuery::ROW_EXPR'
  visit 'pg',
        'CREATE RULE some_rule AS ON SELECT TO some_table DO INSTEAD SELECT * FROM other_table',
        'PgQuery::RULE_STMT'
  visit 'all',
        'SELECT ' \
        "DISTINCT 'id', (SELECT DISTINCT ON ( 'a' ) 'a'), " \
        '1 FROM "a" ' \
        "WHERE 't'::bool " \
        'GROUP BY 1 ' \
        'HAVING "a" > 1 ' \
        'WINDOW "b" AS (PARTITION BY "c" ORDER BY "d" DESC) ' \
        'ORDER BY 1 ASC ' \
        'LIMIT 10 ' \
        'OFFSET 2 ' \
        'FOR UPDATE',
        'PgQuery::SELECT_STMT'
  visit 'pg', 'INSERT INTO som_table (a) VALUES (DEFAULT)', 'PgQuery::SET_TO_DEFAULT'
  visit 'all',
        'SELECT 1 ORDER BY "a" ASC, 2 DESC NULLS FIRST, \'3\' ASC NULLS LAST',
        'PgQuery::SORT_BY'
  visit 'all',
        'SELECT ' \
        'current_date, ' \
        'current_time, ' \
        'current_time(1), ' \
        'current_timestamp, ' \
        'current_timestamp(2), ' \
        'localtime, ' \
        'localtime(3), ' \
        'localtimestamp, ' \
        'localtimestamp(4), ' \
        'current_role, ' \
        'current_user, ' \
        'session_user, ' \
        'user, ' \
        'current_catalog, ' \
        'current_schema',
        'PgQuery::SQL_VALUE_FUNCTION'
  visit 'all', "SELECT 'some_string'", 'PgQuery::STRING'
  visit 'all',
        'SELECT ' \
        'EXISTS (SELECT 1 = 1), ' \
        '"column" > ALL(SELECT AVG("amount") FROM "some_table"), ' \
        '"column" = ANY(SELECT "a" FROM "b"), ' \
        '' \
        '1 < (SELECT 1), ' \
        '' \
        'ARRAY(SELECT 1)' \
        '',
        'PgQuery::SUB_LINK'
  visit 'pg', 'BEGIN; COMMIT', 'PgQuery::TRANSACTION_STMT'
  visit 'pg', 'TRUNCATE public.some_table', 'PgQuery::TRUNCATE_STMT'
  visit 'all', "SELECT 1::int4, 2::bool, '3'::text", 'PgQuery::TYPE_CAST'
  visit 'all', 'SELECT "a"::varchar', 'PgQuery::TYPE_NAME'
  visit 'all',
        'WITH "query" AS (SELECT 1 AS a) ' \
        'UPDATE ONLY "some_table" "table_alias" ' \
        'SET "b" = "query"."a", "d" = DEFAULT, "e" = (SELECT 1), "d" = ROW(DEFAULT) ' \
        'FROM "query", "other_query" WHERE 1 = 1 ' \
        'RETURNING *, "c" AS some_column',
        'PgQuery::UPDATE_STMT'
  visit 'all',
        'UPDATE ONLY "some_table" ' \
        'SET "b" = "query"."a", "c" = 1.0, "d" = \'e`\', "f" = \'t\'::bool ' \
        'WHERE CURRENT OF some_cursor',
        'PgQuery::UPDATE_STMT'
  visit 'pg', 'VACUUM FULL VERBOSE ANALYZE some_table', 'PgQuery::VACUUM_STMT'
  visit 'pg', 'SET LOCAL some_variable TO some_value', 'PgQuery::VARIABLE_SET_STMT'
  visit 'pg', 'SHOW some_variable', 'PgQuery::VARIABLE_SHOW_STMT'
  visit 'pg', 'CREATE VIEW some_view AS (SELECT 1)', 'PgQuery::VIEW_STMT'
  visit 'all',
        'SELECT 1, ' \
        'SUM("a") OVER (RANGE CURRENT ROW), ' \
        'SUM("a") OVER (RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), ' \
        'SUM("a") OVER (RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), ' \
        'SUM("a") OVER (RANGE BETWEEN CURRENT ROW AND CURRENT ROW), ' \
        'SUM("a") OVER (RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING), ' \
        'SUM("a") OVER (ROWS 2 PRECEDING), ' \
        'SUM("a") OVER (ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING), ' \
        'SUM("a") OVER (ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING), ' \
        'SUM("a") OVER (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), ' \
        'SUM("a") OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND 1 FOLLOWING), ' \
        'SUM("a") OVER (ROWS BETWEEN 1 PRECEDING AND UNBOUNDED FOLLOWING), ' \
        'SUM("a") OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), ' \
        'SUM("a") OVER () ' \
        'FROM "a" ' \
        'WINDOW "b" AS (PARTITION BY "c" ORDER BY "d" DESC)',
        'PgQuery::WINDOW_DEF'
  visit 'all', 'WITH "some_name" AS (SELECT \'a\') SELECT "some_name"', 'PgQuery::WITH_CLAUSE'

  it 'implements all operators' do
    sql = 'SELECT ' \
          '11 + 11, ' \
          '12 - 12, ' \
          '10 * 10, ' \
          '13 / 13, ' \
          '13 % 2' \
          '2.0 ^ 3.0, ' \
          ' |/ 16, ' \
          ' ||/ 17, ' \
          '14 !, ' \
          '!! 15, ' \
          ' @ -5, ' \
          '2 & 3, ' \
          '2 | 3, ' \
          '17 # 5, ' \
          ' ~ 5, ' \
          '1 << 4, ' \
          '8 >> 2, ' \
          '8 < 7, ' \
          '5 > 4, ' \
          '9 <= 9, ' \
          '6 >= 6, ' \
          '1 = 1, ' \
          '2 != 3, ' \
          'ARRAY[1, 4, 3] @> ARRAY[3, 1], ' \
          'ARRAY[2, 7] <@ ARRAY[1, 7, 4, 2, 6], ' \
          'ARRAY[1, 4, 3] && ARRAY[2, 1], ' \
          'ARRAY[1, 2, 3] || ARRAY[4, 5, 6], ' \
          'ARRAY[1] || ARRAY[ARRAY[4], ARRAY[7]], ' \
          '3 || ARRAY[4, 5, 6], ' \
          'ARRAY[4, 5, 6] || 7'

    parsed_sql = Arel.sql_to_arel(sql).to_sql
    expect(parsed_sql).to eq sql
  end

  it 'translates FETCH into LIMIT' do
    sql = 'SELECT 1 FETCH FIRST 2 ROWS ONLY'
    parsed_sql = Arel.sql_to_arel(sql).to_sql
    expect(parsed_sql).to eq 'SELECT 1 LIMIT 2'
  end

  it 'translates CAST into ::' do
    sql = 'SELECT CAST(3 AS TEXT)'
    parsed_sql = Arel.sql_to_arel(sql).to_sql
    expect(parsed_sql).to eq 'SELECT 3::text'
  end

  it 'translates SOME into ANY' do
    sql = 'SELECT "a" <= SOME(SELECT 1)'
    parsed_sql = Arel.sql_to_arel(sql).to_sql
    expect(parsed_sql).to eq 'SELECT "a" <= ANY(SELECT 1)'
  end

  it 'removes ALL inside a function' do
    sql = 'SELECT SUM(ALL "a")'
    parsed_sql = Arel.sql_to_arel(sql).to_sql
    expect(parsed_sql).to eq 'SELECT SUM("a")'
  end

  # # NOTE: should run at the end
  # children.each do |child|
  #   sql, pg_query_node = child.metadata[:block].binding.local_variable_get(:args)
  #   puts sql, pg_query_node
  # end
end
