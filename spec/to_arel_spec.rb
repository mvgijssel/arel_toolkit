require 'support/fake_record'
Arel::Table.engine = FakeRecord::Base.new

RSpec.describe ToArel do
  it 'has a version number' do
    expect(ToArel::VERSION).not_to be nil
  end

  describe '.parse' do
    describe 'SELECT' do
      # SELECT "a" AS b FROM "public"."x" WHERE "y" = 5 AND "z" = "y"
      # SELECT "a" AS b FROM "x" WHERE "y" = 5 AND "z" = "y"
      # SELECT "a", "b", max("c") FROM "c" WHERE "d" = 1 GROUP BY "a", "b"
      # SELECT "amount" * 0.5
      # SELECT "m"."name" AS mname, "pname" FROM "manufacturers" m, LATERAL get_product_names("m"."id") pname
      # SELECT "x", "y" FROM "a" FULL JOIN "b" ON 1 > 0
      # SELECT "x", "y" FROM "a" LEFT JOIN "b" ON 1 > 0
      # SELECT "x", "y" FROM "a" NATURAL JOIN "b"
      # SELECT "x", "y" FROM "a" RIGHT JOIN "b" ON 1 > 0
      # SELECT $5
      # SELECT (SELECT 'x')
      # SELECT * FROM "a" ORDER BY "x" ASC NULLS FIRST
      # SELECT * FROM "a" ORDER BY "x" ASC NULLS LAST
      # SELECT * FROM "accounts" WHERE "status" = CASE WHEN "x" = 1 THEN \'active\' ELSE \'inactive\' END
      # SELECT * FROM "x" JOIN (SELECT "n" FROM "z") b ON "a"."id" = "b"."id"
      # SELECT * FROM "x" LIMIT 50
      # SELECT * FROM "x" OFFSET 50
      # SELECT * FROM "x" WHERE "id" IN (1, 2, 3)
      # SELECT * FROM "x" WHERE "id" IN (SELECT "id" FROM "account")
      # SELECT * FROM "x" WHERE "id" NOT IN (1, 2, 3)
      # SELECT * FROM "x" WHERE "x" = ANY(?)
      # SELECT * FROM "x" WHERE "x" = COALESCE("y", ?)
      # SELECT * FROM "x" WHERE "x" BETWEEN SYMMETRIC 20 AND 10
      # SELECT * FROM "x" WHERE "x" BETWEEN \'2016-01-01\' AND \'2016-02-02\'
      # SELECT * FROM "x" WHERE "x" NOT BETWEEN SYMMETRIC 20 AND 10
      # SELECT * FROM "x" WHERE "x" NOT BETWEEN \'2016-01-01\' AND \'2016-02-02\'
      # SELECT * FROM "x" WHERE "x" OR "y"
      # SELECT * FROM "x" WHERE "y" = "z"[?]
      # SELECT * FROM "x" WHERE "y" = "z"[?][?]
      # SELECT * FROM "x" WHERE "y" IS FALSE
      # SELECT * FROM "x" WHERE "y" IS NOT FALSE
      # SELECT * FROM "x" WHERE "y" IS NOT NULL
      # SELECT * FROM "x" WHERE "y" IS NOT TRUE
      # SELECT * FROM "x" WHERE "y" IS NOT UNKNOWN
      # SELECT * FROM "x" WHERE "y" IS NULL
      # SELECT * FROM "x" WHERE "y" IS TRUE
      # SELECT * FROM "x" WHERE "y" IS UNKNOWN
      # SELECT * FROM "x" WHERE NOT "y"
      # SELECT * FROM (SELECT generate_series(0, 100)) a
      # SELECT * FROM (VALUES ('anne', 'smith'), ('bob', 'jones'), ('joe', 'blow')) names(\"first\", \"last\")
      # SELECT * FROM \"users\" WHERE \"name\" LIKE 'postgresql:%';
      # SELECT * FROM \"users\" WHERE \"name\" NOT LIKE 'postgresql:%';
      # SELECT 1 WHERE (1 = 1 AND 2 = 2) OR 2 = 3
      # SELECT 1 WHERE (1 = 1 OR 1 = 2) AND 1 = 2
      # SELECT 1 WHERE 1 = 1 OR 2 = 2 OR 2 = 3
      # SELECT 1::int8
      # SELECT 2 + 2
      # SELECT ?
      # SELECT ?::regclass
      # SELECT CASE 1 > 0 WHEN true THEN \'ok\' ELSE NULL END
      # SELECT CASE WHEN "a"."status" = 1 THEN \'active\' WHEN "a"."status" = 2 THEN \'inactive\' ELSE \'unknown\' END FROM "accounts" a
      # SELECT CASE WHEN "a"."status" = 1 THEN \'active\' WHEN "a"."status" = 2 THEN \'inactive\' END FROM "accounts" a
      # SELECT CASE WHEN EXISTS(SELECT 1) THEN 1 ELSE 2 END
      # SELECT DISTINCT "a", "b", * FROM "c" WHERE "d" = "e"
      # SELECT DISTINCT ON ("a") "a", "b" FROM "c"
      # SELECT NULL FROM "x"
      # SELECT NULLIF("id", 0) AS id FROM "x"
      # SELECT count(*) FROM "x" WHERE "y" IS NOT NULL
      # SELECT count(DISTINCT "a") FROM "x" WHERE "y" IS NOT NULL
      # SELECT current_time(2)
      # SELECT current_timestamp
      # SELECT rank(*) OVER ()
      # SELECT rank(*) OVER (ORDER BY "id")
      # SELECT rank(*) OVER (PARTITION BY "id")
      # SELECT rank(*) OVER (PARTITION BY "id", "id2" ORDER BY "id" DESC, "id2")
      # SELECT sum("price_cents") FROM "products"

      describe 'to arel and back' do
        it 'parses a simple query' do
          given_sql = 'SELECT id FROM users'
          expected_sql = 'SELECT "id" FROM "users"'

          expect(ToArel.parse(given_sql).to_sql).to eq expected_sql
        end

        it 'parses a query with an aggregate' do
          given_sql = 'SELECT count(id) FROM users'
          expected_sql = 'SELECT COUNT("id") FROM "users"'

          expect(ToArel.parse(given_sql).to_sql).to eq expected_sql
        end

        it 'parses a query with a subquery' do
          given_sql = 'SELECT id, (SELECT id FROM users LIMIT 1) FROM photos'
          expected_sql = 'SELECT "id", (SELECT  "id" FROM "users" LIMIT 1) FROM "photos"'

          expect(ToArel.parse(given_sql).to_sql).to eq expected_sql
        end

        it 'parses a query with an join' do
          given_sql = 'SELECT id FROM photos INNER JOIN users ON photos.user_id = users.id'
          expected_sql = 'SELECT "id" FROM "photos" ' \
                         'INNER JOIN "users" ON "photos"."user_id" = "users"."id"'

          expect(ToArel.parse(given_sql).to_sql).to eq expected_sql
        end

        it 'parses a query with multiple different joins' do
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

          expect(ToArel.parse(given_sql).to_sql).to eq expected_sql
        end

        it 'parses a query with multiple order statements' do
          given_sql = 'SELECT id FROM posts ORDER BY posts.name ASC, posts.id DESC'
          expected_sql = 'SELECT "id" FROM "posts" ORDER BY "posts"."name" ASC, "posts"."id" DESC'

          expect(ToArel.parse(given_sql).to_sql).to eq expected_sql
        end
      end
    end

    xdescribe 'UPDATE' do
    end

    xdescribe 'INSERT' do
    end
  end
end
