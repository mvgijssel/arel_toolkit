describe 'Arel.sql_to_arel' do
  def sql_arel_sql(sql)
    Arel.sql_to_arel(sql).to_sql
  end

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
    else
      raise 'i dunno'
    end
  end

  define :ast_contains do |expected|
    match do |pg_query_tree|
      ast_contains_constant(pg_query_tree, expected)
    end

    failure_message do |pg_query_tree|
      "expected that #{pg_query_tree} would contain `#{expected}`"
    end
  end

  shared_examples 'sql' do |sql, pg_query_node|
    it "expects `#{pg_query_node}` to exist" do
      expect(Object.const_defined?(pg_query_node)).to eq true
    end

    it "expects `#{pg_query_node}` to appear in the ast" do
      tree = PgQuery.parse(sql).tree
      expect(tree).to ast_contains(Object.const_get(pg_query_node))
    end

    it "expects the sql `#{sql}` to parse the same" do
      parsed_sql = Arel.sql_to_arel(sql).to_sql
      expect(parsed_sql).to eq sql
    end
  end

  visit 'sql', 'SELECT ARRAY[1]', 'PgQuery::A_ARRAY_EXPR'
  visit 'sql', 'SELECT 1', 'PgQuery::A_CONST'
  visit 'sql', 'SELECT 1 IN (1)', 'PgQuery::A_EXPR'
  visit 'sql', 'SELECT field[1]', 'PgQuery::A_INDICES'
  visit 'sql', 'SELECT something[1]', 'PgQuery::A_INDIRECTION'
  visit 'sql', 'SELECT *', 'PgQuery::A_STAR'
  # visit 'sql', 'GRANT INSERT, UPDATE ON mytable TO myuser', 'PgQuery::ACCESS_PRIV'
  visit 'sql', 'SELECT 1 FROM "a" "b"', 'PgQuery::ALIAS'
  # visit 'sql', 'ALTER TABLE stuff ADD COLUMN address text', 'PgQuery::ALTER_TABLE_CMD'
  # visit 'sql', 'ALTER TABLE stuff ADD COLUMN address text', 'PgQuery::ALTER_TABLE_STMT'
  visit 'sql', "SELECT B'0101'", 'PgQuery::BIT_STRING'
  visit 'sql', 'SELECT 1 WHERE 1 AND 2', 'PgQuery::BOOL_EXPR'
  visit 'sql', 'SELECT 1 WHERE 1 IS TRUE', 'PgQuery::BOOLEAN_TEST'
  visit 'sql', 'SELECT CASE WHEN "a" = "b" THEN 2 = 2 WHEN "a" THEN \'b\' ELSE 1 = 1 END', 'PgQuery::CASE_EXPR'
  visit 'sql', "SELECT CASE \"field\" WHEN \"a\" THEN 1 WHEN 'b' THEN 0 ELSE 2 END", 'PgQuery::CASE_WHEN'
  # visit 'sql', "CHECKPOINT", 'PgQuery::CHECK_POINT_STMT'
  # visit 'sql', "CLOSE cursor;", 'PgQuery::CLOSE_PORTAL_STMT'
  visit 'sql', "SELECT COALESCE(\"a\", NULL, 2, 'b')", 'PgQuery::COALESCE_EXPR'
  # visit 'sql', 'SELECT a COLLATE "C"', 'PgQuery::COLLATE_CLAUSE'
  # visit 'sql', 'CREATE TABLE a (column_def_column text)', 'PgQuery::COLUMN_DEF'
  visit 'sql', 'SELECT "id"', 'PgQuery::COLUMN_REF'
  visit 'sql', 'WITH "a" AS (SELECT 1) SELECT * FROM "a"', 'PgQuery::COMMON_TABLE_EXPR'
  visit 'sql', 'WITH RECURSIVE "c" AS (SELECT \'a\') SELECT \'b\', 1 FROM "c"', 'PgQuery::COMMON_TABLE_EXPR'
  # visit 'sql', 'CREATE TABLE a (b integer NOT NULL)', 'PgQuery::CONSTRAINT'
  # visit 'sql', 'COPY reports TO STDOUT', 'PgQuery::COPY_STMT'
  # visit 'sql', "CREATE FUNCTION a(integer) RETURNS integer AS 'SELECT $1;' LANGUAGE SQL;", 'PgQuery::CREATE_FUNCTION_STMT'
  # visit 'sql', "CREATE SCHEMA secure", 'PgQuery::CREATE_SCHEMA_STMT'
  # visit 'sql', "CREATE TABLE a (b integer)", 'PgQuery::CREATE_STMT'
  # visit 'sql', "CREATE TABLE a AS (SELECT * FROM reports)", 'PgQuery::CREATE_TABLE_AS_STMT'
  # visit 'sql', "CREATE TRIGGER a AFTER INSERT ON b FOR EACH ROW EXECUTE PROCEDURE b()", 'PgQuery::CREATE_TRIG_STMT'
  # visit 'sql', "DEALLOCATE some_prepared_statement", 'PgQuery::DEALLOCATE_STMT'
  # visit 'sql', "DECLARE a CURSOR FOR SELECT 1", 'PgQuery::DECLARE_CURSOR_STMT'
  # visit 'sql', "DO $$ a $$", 'PgQuery::DEF_ELEM'
  # visit 'sql', 'DELETE FROM a', 'PgQuery::DELETE_STMT'
  # visit 'sql', 'DISCARD ALL', 'PgQuery::DISCARD_STMT'
  # visit 'sql', "DO $$ a $$", 'PgQuery::DO_STMT'
  # visit 'sql', "DROP TABLE some_tablr", 'PgQuery::DROP_STMT'

  # # NOTE: should run at the end
  # children.each do |child|
  #   sql, pg_query_node = child.metadata[:block].binding.local_variable_get(:args)
  #   puts sql, pg_query_node
  # end
end
