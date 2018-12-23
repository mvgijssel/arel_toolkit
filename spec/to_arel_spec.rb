require 'support/fake_record'
Arel::Table.engine = FakeRecord::Base.new

RSpec.describe ToArel do
  it 'has a version number' do
    expect(ToArel::VERSION).not_to be nil
  end

  describe '.parse' do
    describe 'SELECT' do

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

        it 'parses a query with a where' do
          given_sql = 'SELECT id FROM posts WHERE posts.id = 1'
          expected_sql = 'SELECT "id" FROM "posts" WHERE "posts"."id" = 1'

          expect(ToArel.parse(given_sql).to_sql).to eq expected_sql
        end
      end

      it do
        a = %Q(SELECT "a" AS b FROM "public"."x" WHERE "y" = 5 AND "z" = "y")
        b = %Q(SELECT "a" AS b FROM "public"."x" WHERE "y" = 5 AND "z" = "y")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT "a" AS b FROM "x" WHERE "y" = 5 AND "z" = "y")
        b = %Q(SELECT "a" AS b FROM "x" WHERE "y" = 5 AND "z" = "y")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT "a", "b", max("c") FROM "c" WHERE "d" = 1 GROUP BY "a", "b")
        b = %Q(SELECT "a", "b", max("c") FROM "c" WHERE "d" = 1 GROUP BY "a", "b")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT "amount" * 0.5)
        b = %Q(SELECT "amount" * 0.5)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT "m"."name" AS mname, "pname" FROM "manufacturers" m, LATERAL get_product_names("m"."id") pname)
        b = %Q(SELECT "m"."name" AS mname, "pname" FROM "manufacturers" m, LATERAL get_product_names("m"."id") pname)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT "x", "y" FROM "a" FULL JOIN "b" ON 1 > 0)
        b = %Q(SELECT "x", "y" FROM "a" FULL JOIN "b" ON 1 > 0)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT "x", "y" FROM "a" LEFT JOIN "b" ON 1 > 0)
        b = %Q(SELECT "x", "y" FROM "a" LEFT JOIN "b" ON 1 > 0)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT "x", "y" FROM "a" NATURAL JOIN "b")
        b = %Q(SELECT "x", "y" FROM "a" NATURAL JOIN "b")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT "x", "y" FROM "a" RIGHT JOIN "b" ON 1 > 0)
        b = %Q(SELECT "x", "y" FROM "a" RIGHT JOIN "b" ON 1 > 0)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT (SELECT 'x'))
        b = %Q(SELECT (SELECT 'x'))
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "a" ORDER BY "x" ASC NULLS FIRST)
        b = %Q(SELECT * FROM "a" ORDER BY "x" ASC NULLS FIRST)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "a" ORDER BY "x" ASC NULLS LAST)
        b = %Q(SELECT * FROM "a" ORDER BY "x" ASC NULLS LAST)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "accounts" WHERE "status" = CASE WHEN "x" = 1 THEN \'active\' ELSE \'inactive\' END)
        b = %Q(SELECT * FROM "accounts" WHERE "status" = CASE WHEN "x" = 1 THEN \'active\' ELSE \'inactive\' END)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" JOIN (SELECT "n" FROM "z") b ON "a"."id" = "b"."id")
        b = %Q(SELECT * FROM "x" JOIN (SELECT "n" FROM "z") b ON "a"."id" = "b"."id")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" LIMIT 50)
        b = %Q(SELECT * FROM "x" LIMIT 50)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" OFFSET 50)
        b = %Q(SELECT * FROM "x" OFFSET 50)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "id" IN (1, 2, 3))
        b = %Q(SELECT * FROM "x" WHERE "id" IN (1, 2, 3))
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "id" IN (SELECT "id" FROM "account"))
        b = %Q(SELECT * FROM "x" WHERE "id" IN (SELECT "id" FROM "account"))
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "id" NOT IN (1, 2, 3))
        b = %Q(SELECT * FROM "x" WHERE "id" NOT IN (1, 2, 3))
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "x" = ANY(?))
        b = %Q(SELECT * FROM "x" WHERE "x" = ANY(?))
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "x" = COALESCE("y", ?))
        b = %Q(SELECT * FROM "x" WHERE "x" = COALESCE("y", ?))
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "x" BETWEEN SYMMETRIC 20 AND 10)
        b = %Q(SELECT * FROM "x" WHERE "x" BETWEEN SYMMETRIC 20 AND 10)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "x" BETWEEN \'2016-01-01\' AND \'2016-02-02\')
        b = %Q(SELECT * FROM "x" WHERE "x" BETWEEN \'2016-01-01\' AND \'2016-02-02\')
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "x" NOT BETWEEN SYMMETRIC 20 AND 10)
        b = %Q(SELECT * FROM "x" WHERE "x" NOT BETWEEN SYMMETRIC 20 AND 10)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "x" NOT BETWEEN \'2016-01-01\' AND \'2016-02-02\')
        b = %Q(SELECT * FROM "x" WHERE "x" NOT BETWEEN \'2016-01-01\' AND \'2016-02-02\')
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "x" OR "y")
        b = %Q(SELECT * FROM "x" WHERE "x" OR "y")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "y" = "z"[?])
        b = %Q(SELECT * FROM "x" WHERE "y" = "z"[?])
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "y" = "z"[?][?])
        b = %Q(SELECT * FROM "x" WHERE "y" = "z"[?][?])
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "y" IS FALSE)
        b = %Q(SELECT * FROM "x" WHERE "y" IS FALSE)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "y" IS NOT FALSE)
        b = %Q(SELECT * FROM "x" WHERE "y" IS NOT FALSE)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "y" IS NOT NULL)
        b = %Q(SELECT * FROM "x" WHERE "y" IS NOT NULL)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "y" IS NOT TRUE)
        b = %Q(SELECT * FROM "x" WHERE "y" IS NOT TRUE)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "y" IS NOT UNKNOWN)
        b = %Q(SELECT * FROM "x" WHERE "y" IS NOT UNKNOWN)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "y" IS NULL)
        b = %Q(SELECT * FROM "x" WHERE "y" IS NULL)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "y" IS TRUE)
        b = %Q(SELECT * FROM "x" WHERE "y" IS TRUE)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE "y" IS UNKNOWN)
        b = %Q(SELECT * FROM "x" WHERE "y" IS UNKNOWN)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM "x" WHERE NOT "y")
        b = %Q(SELECT * FROM "x" WHERE NOT "y")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM (SELECT generate_series(0, 100)) a)
        b = %Q(SELECT * FROM (SELECT generate_series(0, 100)) a)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM (VALUES ('anne', 'smith'), ('bob', 'jones'), ('joe', 'blow')) names(\"first\", \"last\"))
        b = %Q(SELECT * FROM (VALUES ('anne', 'smith'), ('bob', 'jones'), ('joe', 'blow')) names(\"first\", \"last\"))
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM \"users\" WHERE \"name\" LIKE 'postgresql:%';)
        b = %Q(SELECT * FROM \"users\" WHERE \"name\" LIKE 'postgresql:%';)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT * FROM \"users\" WHERE \"name\" NOT LIKE 'postgresql:%';)
        b = %Q(SELECT * FROM \"users\" WHERE \"name\" NOT LIKE 'postgresql:%';)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT ?::regclass)
        b = %Q(SELECT ?::regclass)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT CASE 1 > 0 WHEN true THEN \'ok\' ELSE NULL END)
        b = %Q(SELECT CASE 1 > 0 WHEN true THEN \'ok\' ELSE NULL END)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT CASE WHEN "a"."status" = 1 THEN \'active\' WHEN "a"."status" = 2 THEN \'inactive\' ELSE \'unknown\' END FROM "accounts" a)
        b = %Q(SELECT CASE WHEN "a"."status" = 1 THEN \'active\' WHEN "a"."status" = 2 THEN \'inactive\' ELSE \'unknown\' END FROM "accounts" a)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT CASE WHEN "a"."status" = 1 THEN \'active\' WHEN "a"."status" = 2 THEN \'inactive\' END FROM "accounts" a)
        b = %Q(SELECT CASE WHEN "a"."status" = 1 THEN \'active\' WHEN "a"."status" = 2 THEN \'inactive\' END FROM "accounts" a)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT DISTINCT "a", "b", * FROM "c" WHERE "d" = "e")
        b = %Q(SELECT DISTINCT "a", "b", * FROM "c" WHERE "d" = "e")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT DISTINCT ON ("a") "a", "b" FROM "c")
        b = %Q(SELECT DISTINCT ON ("a") "a", "b" FROM "c")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT NULL FROM "x")
        b = %Q(SELECT NULL FROM "x")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT NULLIF("id", 0) AS id FROM "x")
        b = %Q(SELECT NULLIF("id", 0) AS id FROM "x")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT count(*) FROM "x" WHERE "y" IS NOT NULL)
        b = %Q(SELECT count(*) FROM "x" WHERE "y" IS NOT NULL)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT count(DISTINCT "a") FROM "x" WHERE "y" IS NOT NULL)
        b = %Q(SELECT count(DISTINCT "a") FROM "x" WHERE "y" IS NOT NULL)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT current_time(2))
        b = %Q(SELECT current_time(2))
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT current_timestamp)
        b = %Q(SELECT current_timestamp)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT rank(*) OVER ())
        b = %Q(SELECT rank(*) OVER ())
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT rank(*) OVER (ORDER BY "id"))
        b = %Q(SELECT rank(*) OVER (ORDER BY "id"))
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT rank(*) OVER (PARTITION BY "id"))
        b = %Q(SELECT rank(*) OVER (PARTITION BY "id"))
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT rank(*) OVER (PARTITION BY "id", "id2" ORDER BY "id" DESC, "id2"))
        b = %Q(SELECT rank(*) OVER (PARTITION BY "id", "id2" ORDER BY "id" DESC, "id2"))
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT sum("price_cents") FROM "products")
        b = %Q(SELECT sum("price_cents") FROM "products")
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT $5)
        b = %Q(SELECT $5)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT 1 WHERE (1 = 1 AND 2 = 2) OR 2 = 3)
        b = %Q(SELECT 1 WHERE (1 = 1 AND 2 = 2) OR 2 = 3)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT 1 WHERE (1 = 1 OR 1 = 2) AND 1 = 2)
        b = %Q(SELECT 1 WHERE (1 = 1 OR 1 = 2) AND 1 = 2)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT 1 WHERE 1 = 1 OR 2 = 2 OR 2 = 3)
        b = %Q(SELECT 1 WHERE 1 = 1 OR 2 = 2 OR 2 = 3)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT 1::int8)
        b =Q(SELECT 1::int8)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT 2 + 2)
        b = %Q(SELECT 2 + 2)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT ?)
        b = %Q(SELECT ?)
        expect(ToArel.parse(a).to_sql).to eq b
      end

      it do
        a = %Q(SELECT CASE WHEN EXISTS(SELECT 1) THEN 1 ELSE 2 END)
        b = %Q(SELECT CASE WHEN EXISTS(SELECT 1) THEN 1 ELSE 2 END)
        expect(ToArel.parse(a).to_sql).to eq b
      end
    end

    xdescribe 'UPDATE' do
    end

    xdescribe 'INSERT' do
    end
  end
end
