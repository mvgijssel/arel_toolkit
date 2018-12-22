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
      end
    end

    xdescribe 'UPDATE' do
    end

    xdescribe 'INSERT' do
    end
  end
end
