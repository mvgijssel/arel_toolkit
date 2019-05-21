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

  shared_examples "a visited node" do |sql, pg_query_node|
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

  it_behaves_like 'a visited node', 'SELECT ARRAY[1]', 'PgQuery::A_ARRAY_EXPR'
  it_behaves_like 'a visited node', 'SELECT 1', 'PgQuery::A_CONST'
  it_behaves_like 'a visited node', 'SELECT 1 IN (1)', 'PgQuery::A_EXPR'
  it_behaves_like 'a visited node', 'SELECT field[1]', 'PgQuery::A_INDICES'
  it_behaves_like 'a visited node', 'SELECT something[1]', 'PgQuery::A_INDIRECTION'
  it_behaves_like 'a visited node', 'SELECT *', 'PgQuery::A_STAR'
  # it_behaves_like 'a visited node', 'GRANT INSERT, UPDATE ON mytable TO myuser', 'PgQuery::ACCESS_PRIV'
  it_behaves_like 'a visited node', 'SELECT 1 FROM "a" "b"', 'PgQuery::ALIAS'
  # it_behaves_like 'a visited node', 'ALTER TABLE stuff ADD COLUMN address text', 'PgQuery::ALTER_TABLE_CMD'
  # it_behaves_like 'a visited node', 'ALTER TABLE stuff ADD COLUMN address text', 'PgQuery::ALTER_TABLE_STMT'
  it_behaves_like 'a visited node', "SELECT B'0101'", 'PgQuery::BIT_STRING'
  it_behaves_like 'a visited node', "SELECT 1 WHERE 1 AND 2", 'PgQuery::BOOL_EXPR'
  it_behaves_like 'a visited node', "SELECT 1 WHERE 1 IS TRUE", 'PgQuery::BOOLEAN_TEST'
  it_behaves_like 'a visited node', "SELECT CASE WHEN 1 THEN 1 ELSE 2 END", 'PgQuery::CASE_EXPR'

  # # NOTE: should run at the end
  # children.each do |child|
  #   sql, pg_query_node = child.metadata[:block].binding.local_variable_get(:args)
  #   puts sql, pg_query_node
  # end

  describe 'mathematical functions and operators' do
    it do
      sql = %(SELECT 2 + 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT 2 - 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT 2 * 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT 2 / 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    xit do
      sql = %(SELECT 2 % 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT 2 ^ 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    xit do
      sql = %(SELECT 2 |/ 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    xit do
      sql = %(SELECT 2 ||/ 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    xit do
      sql = %(SELECT 2 ! 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    xit do
      sql = %(SELECT 2 !! 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT 2 & 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT 2 | 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    xit do
      sql = %(SELECT 2 # 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT 2 << 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT 2 >> 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    xit do
      sql = %(SELECT @ 2)
      expect(sql_arel_sql(sql)).to eq sql
    end

    xit do
      sql = %(SELECT ~ 2)
      expect(sql_arel_sql(sql)).to eq sql
    end
  end

  describe 'row and array comparisons' do
    # IN
    it do
      sql = %(SELECT 1 IN (1, 2))
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT 1 NOT IN (1, 2))
      expect(sql_arel_sql(sql)).to eq sql
    end

    xit do
      # ANY
    end

    xit do
      # SOME
    end

    xit do
      # ALL
    end
  end

  describe 'conditional expressions' do
    xit do
      # CASE
    end

    it do
      sql = %(SELECT COALESCE(1, 1))
      expect(sql_arel_sql(sql)).to eq sql
    end

    xit do
      sql = %(SELECT NULLIF(1, 10))
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT GREATEST(1, 10))
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT LEAST(1, 10))
      expect(sql_arel_sql(sql)).to eq sql
    end
  end

  describe 'grouping' do
    it do
      sql = %(SELECT "id" FROM "salaries" GROUP BY "salary")
      expect(sql_arel_sql(sql)).to eq sql
    end
  end

  describe 'having' do
    it do
      sql = %(SELECT "id" FROM "salaries" GROUP BY "salary" HAVING MIN("salary") > AVG("salary"))
      expect(sql_arel_sql(sql)).to eq sql
    end
  end

  describe 'aggregate functions' do
    it do
      sql = %(SELECT AVG("salary"))
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT COUNT(*))
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT COUNT("salary"))
      expect(sql_arel_sql(sql)).to eq sql
    end

    xit do
      sql = %(SELECT EVERY("salary"))
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT MAX("salary"))
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT MIN("salary"))
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT SUM("salary"))
      expect(sql_arel_sql(sql)).to eq sql
    end
  end

  describe 'window clause' do
    it do
      sql = %(SELECT SUM("salary") OVER ())
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT "salary", SUM("salary") OVER (ORDER BY "salary"))
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT "salary", SUM("salary") OVER (PARTITION BY "salary"))
      expect(sql_arel_sql(sql)).to eq sql
    end

    it do
      sql = %(SELECT "salary", SUM("salary") OVER (PARTITION BY "salary" ORDER BY "salary"))
      expect(sql_arel_sql(sql)).to eq sql
    end
  end

  it 'parses a simple query' do
    given_sql = 'SELECT id FROM users'
    expected_sql = 'SELECT "id" FROM "users"'

    expect(Arel.sql_to_arel(given_sql).to_sql).to eq expected_sql
  end

  it 'parses a query with an aggregate' do
    given_sql = 'SELECT count(id) FROM users'
    expected_sql = 'SELECT COUNT("id") FROM "users"'

    expect(Arel.sql_to_arel(given_sql).to_sql).to eq expected_sql
  end

  xit 'parses a query with a subquery' do
    given_sql = 'SELECT id, (SELECT id FROM users LIMIT 1) FROM photos'
    expected_sql = 'SELECT "id", (SELECT  "id" FROM "users" LIMIT 1) FROM "photos"'

    expect(Arel.sql_to_arel(given_sql).to_sql).to eq expected_sql
  end

  it 'parses a query with an join' do
    given_sql = 'SELECT id FROM photos INNER JOIN users ON photos.user_id = users.id'
    expected_sql = 'SELECT "id" FROM "photos" ' \
                   'INNER JOIN "users" ON "photos"."user_id" = "users"."id"'

    expect(Arel.sql_to_arel(given_sql).to_sql).to eq expected_sql
  end

  xit 'parses a query with multiple different joins' do
    given_sql = <<-SQL
      SELECT
        id
      FROM
        users, teams

      INNER JOIN
        photos
      ON
        photos.user_id = users.id

      RIGHT JOIN
        locations
      ON
        locations.photo_id = photos.id

      LEFT JOIN
        users AS l_users
      ON
        l_users.id = location.user_id
    SQL

    expected_sql =
      'SELECT "id" FROM "users", "teams" ' \
      'INNER JOIN "photos" ON "photos"."user_id" = "users"."id" ' \
      'RIGHT OUTER JOIN "locations" ON "locations"."photo_id" = "photos"."id" ' \
      'LEFT OUTER JOIN "users" "l_users" ON "l_users"."id" = "location"."user_id"'

    expect(Arel.sql_to_arel(given_sql).to_sql).to eq expected_sql
  end

  it 'parses a query with multiple order statements' do
    given_sql = 'SELECT id FROM posts ORDER BY posts.name ASC, posts.id DESC'
    expected_sql = 'SELECT "id" FROM "posts" ORDER BY "posts"."name" ASC, "posts"."id" DESC'

    expect(Arel.sql_to_arel(given_sql).to_sql).to eq expected_sql
  end

  it 'parses a query with a where' do
    given_sql = 'SELECT id FROM posts WHERE posts.id = 1'
    expected_sql = 'SELECT "id" FROM "posts" WHERE "posts"."id" = 1'

    expect(Arel.sql_to_arel(given_sql).to_sql).to eq expected_sql
  end

  it do
    a = %(SELECT * FROM "x" WHERE "y" IS NOT NULL)
    b = %(SELECT * FROM "x" WHERE "y" IS NOT NULL)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "y" IS NULL)
    b = %(SELECT * FROM "x" WHERE "y" IS NULL)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT "a" AS b FROM "public"."x" WHERE "y" = 5 AND "z" = "y")
    b = %(SELECT "a" AS b FROM "public"."x" WHERE "y" = 5 AND "z" = "y")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT "a" AS b FROM "x" WHERE "y" = 5 AND "z" = "y")
    b = %(SELECT "a" AS b FROM "x" WHERE "y" = 5 AND "z" = "y")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT "a", "b", max("c") FROM "c" WHERE "d" = 1 GROUP BY "a", "b")
    b = %(SELECT "a", "b", max("c") FROM "c" WHERE "d" = 1 GROUP BY "a", "b")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT "amount" * 0.5)
    b = %(SELECT "amount" * 0.5)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT "x", "y" FROM "a" FULL JOIN "b" ON 1 > 0)
    b = %(SELECT "x", "y" FROM "a" FULL JOIN "b" ON 1 > 0)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT "x", "y" FROM "a" LEFT JOIN "b" ON 1 > 0)
    b = %(SELECT "x", "y" FROM "a" LEFT OUTER JOIN "b" ON 1 > 0)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT "x", "y" FROM "a" NATURAL JOIN "b")
    b = %(SELECT "x", "y" FROM "a" NATURAL JOIN "b")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT "x", "y" FROM "a" RIGHT JOIN "b" ON 1 > 0)
    b = %(SELECT "x", "y" FROM "a" RIGHT JOIN "b" ON 1 > 0)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT (SELECT 'x'))
    b = %(SELECT (SELECT 'x'))
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM "a" ORDER BY "x" ASC NULLS FIRST)
    b = %(SELECT * FROM "a" ORDER BY "x" ASC NULLS FIRST)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM "a" ORDER BY "x" ASC NULLS LAST)
    b = %(SELECT * FROM "a" ORDER BY "x" ASC NULLS LAST)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "a" WHERE "stat" = CASE WHEN "x" = 1 THEN \'active\' ELSE \'inactive\' END)
    b = %(SELECT * FROM "a" WHERE "stat" = CASE WHEN "x" = 1 THEN \'active\' ELSE \'inactive\' END)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM "x" JOIN (SELECT "n" FROM "z") b ON "a"."id" = "b"."id")
    b = %(SELECT * FROM "x" JOIN (SELECT "n" FROM "z") b ON "a"."id" = "b"."id")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" LIMIT 50)
    b = %(SELECT * FROM "x" LIMIT 50)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" OFFSET 50)
    b = %(SELECT * FROM "x" OFFSET 50)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "id" IN (1, 2, 3))
    b = %(SELECT * FROM "x" WHERE "id" IN (1, 2, 3))
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM "x" WHERE "id" IN (SELECT "id" FROM "account"))
    b = %(SELECT * FROM "x" WHERE "id" IN (SELECT "id" FROM "account"))
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "id" NOT IN (1, 2, 3))
    b = %(SELECT * FROM "x" WHERE "id" NOT IN (1, 2, 3))
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM "x" WHERE "x" = ANY(?))
    b = %(SELECT * FROM "x" WHERE "x" = ANY(?))
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT COALESCE(NULL, 10))
    b = %(SELECT COALESCE(NULL, 10))
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "x" = COALESCE("y", ?))
    b = %(SELECT * FROM "x" WHERE "x" = COALESCE("y", ?))
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "x" BETWEEN \'2016-01-01\' AND \'2016-02-02\')
    b = %(SELECT * FROM "x" WHERE "x" BETWEEN \'2016-01-01\' AND \'2016-02-02\')
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "x" OR "y")
    b = %(SELECT * FROM "x" WHERE "x" OR "y")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "y" IS FALSE)
    b = %(SELECT * FROM "x" WHERE "y" IS FALSE)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "y" IS NOT FALSE)
    b = %(SELECT * FROM "x" WHERE "y" IS NOT FALSE)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "y" IS TRUE)
    b = %(SELECT * FROM "x" WHERE "y" IS TRUE)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "y" IS NOT TRUE)
    b = %(SELECT * FROM "x" WHERE "y" IS NOT TRUE)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "y" IS UNKNOWN)
    b = %(SELECT * FROM "x" WHERE "y" IS UNKNOWN)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "y" IS NOT UNKNOWN)
    b = %(SELECT * FROM "x" WHERE "y" IS NOT UNKNOWN)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE "y" IS NULL)
    b = %(SELECT * FROM "x" WHERE "y" IS NULL)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT CASE 1 > 0 WHEN true THEN 'ok' ELSE NULL END)
    b = %(SELECT CASE 1 > 0 WHEN TRUE THEN 'ok' ELSE NULL END)
    expect(Arel.sql_to_arel(a).to_sql).to eq b

    c = %(SELECT CASE 1 > 0 WHEN TRUE THEN 'ok' ELSE NULL END)
    d = %(SELECT CASE 1 > 0 WHEN TRUE THEN 'ok' ELSE NULL END)
    expect(Arel.sql_to_arel(c).to_sql).to eq d
  end

  it do
    a = %(SELECT * FROM (SELECT generate_series(0, 100)) a)
    b = %(SELECT * FROM (SELECT GENERATE_SERIES(0, 100)) \"a\")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT NULL FROM "x")
    b = %(SELECT NULL FROM "x")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT current_time)
    b = %(SELECT current_time)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT current_date)
    b = %(SELECT current_date)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT current_time(2))
    b = %(SELECT current_time(2))
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT current_timestamp)
    b = %(SELECT current_timestamp)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT * FROM "x" WHERE NOT "y")
    b = %(SELECT * FROM "x" WHERE NOT ("y"))
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT DISTINCT "a", "b", * FROM "c" WHERE "d" = "e")
    b = %(SELECT DISTINCT "a", "b", * FROM "c" WHERE "d" = "e")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT count(*) FROM "x" WHERE "y" IS NOT NULL)
    b = %(SELECT COUNT(*) FROM "x" WHERE "y" IS NOT NULL)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  it do
    a = %(SELECT sum("price_cents") FROM "products")
    b = %(SELECT SUM("price_cents") FROM "products")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM "x" WHERE "x" NOT BETWEEN SYMMETRIC 20 AND 10)
    b = %(SELECT * FROM "x" WHERE "x" NOT BETWEEN SYMMETRIC 20 AND 10)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM "x" WHERE "x" BETWEEN SYMMETRIC 20 AND 10)
    b = %(SELECT * FROM "x" WHERE "x" BETWEEN SYMMETRIC 20 AND 10)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM "x" WHERE "x" NOT BETWEEN '2016-01-01' AND '2016-02-02')
    b = %(SELECT * FROM "x" WHERE "x" NOT BETWEEN '2016-01-01' AND '2016-02-02')

    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM "x" WHERE "y" = "z"[?])
    b = %(SELECT * FROM "x" WHERE "y" = "z"[?])
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM "x" WHERE "y" = "z"[?][?])
    b = %(SELECT * FROM "x" WHERE "y" = "z"[?][?])
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM (VALUES ('anne', 'smxith')) names(\"first\", \"last\"))
    b = %(SELECT * FROM (VALUES ('anne', 'smxith')) names(\"first\", \"last\"))
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM \"users\" WHERE \"name\" LIKE 'postgresql:%';)
    b = %(SELECT * FROM \"users\" WHERE \"name\" LIKE 'postgresql:%';)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT * FROM \"users\" WHERE \"name\" NOT LIKE 'postgresql:%';)
    b = %(SELECT * FROM \"users\" WHERE \"name\" NOT LIKE 'postgresql:%';)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT ?::regclass)
    b = %(SELECT ?::regclass)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT DISTINCT ON ("a") "a", "b" FROM "c")
    b = %(SELECT DISTINCT ON ("a") "a", "b" FROM "c")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT NULLIF("id", 0) AS id FROM "x")
    b = %(SELECT NULLIF("id", 0) AS id FROM "x")
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  xit do
    a = %(SELECT $5)
    b = %(SELECT $5)
    expect(Arel.sql_to_arel(a).to_sql).to eq b
  end

  describe 'boolean logic' do
    it do
      a = %(SELECT (1 AND 2) OR 3)
      b = %(SELECT (1 AND 2) OR 3)
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    it do
      a = %(SELECT 1 OR (2 AND 3))
      b = %(SELECT 1 OR (2 AND 3))
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    it do
      a = %(SELECT 1 OR 2 OR 3)
      b = %(SELECT 1 OR 2 OR 3)
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    it do
      a = %(SELECT 1 OR (2 OR 3))
      b = %(SELECT 1 OR (2 OR 3))
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    it do
      a = %(SELECT 1 OR NOT 2)
      b = %(SELECT 1 OR (NOT (2)))
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end
  end

  describe 'columns' do
    it 'parses columns without a table' do
      a = %(SELECT id)
      b = %(SELECT "id")
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    it 'parses columns with a table' do
      a = %(SELECT posts.id)
      b = %(SELECT "posts"."id")
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    it 'parses multi reference columns' do
      a = %(SELECT posts.id.yes)
      b = %(SELECT "posts"."id"."yes")
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    it do
      a = %(SELECT 1 WHERE (1 = 1 AND 2 = 2) OR 2 = 3)
      b = %(SELECT 1 WHERE (1 = 1 AND 2 = 2) OR 2 = 3)
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    it do
      a = %(SELECT 1 WHERE (1 = 1 OR 1 = 2) AND 1 = 2)
      b = %(SELECT 1 WHERE (1 = 1 OR 1 = 2) AND 1 = 2)
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    it do
      a = %(SELECT 1 WHERE 1 = 1 OR 2 = 2 OR 2 = 3)
      b = %(SELECT 1 WHERE 1 = 1 OR 2 = 2 OR 2 = 3)
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    xit do
      a = %(SELECT 1::int8)
      b = Q(SELECT(1.int8))
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    xit do
      a = %(SELECT ?)
      b = %(SELECT ?)
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    it do
      a = %(SELECT CASE WHEN EXISTS(SELECT 1) THEN 1 ELSE 2 END)
      b = %(SELECT CASE WHEN EXISTS (SELECT 1) THEN 1 ELSE 2 END)
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end

    describe 'not supported?' do
      xit do
        a = %(SELECT "x", "y" FROM "a" NATURAL JOIN "b")
        b = %(SELECT "x", "y" FROM "a" NATURAL JOIN "b")
        expect(Arel.sql_to_arel(a).to_sql).to eq b
      end
    end

    it do
      a = %(SELECT CASE WHEN EXISTS(SELECT 1) THEN 1 ELSE 2 END)
      b = %(SELECT CASE WHEN EXISTS (SELECT 1) THEN 1 ELSE 2 END)
      expect(Arel.sql_to_arel(a).to_sql).to eq b
    end
  end
end
