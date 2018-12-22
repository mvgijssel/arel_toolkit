require 'support/fake_record'
Arel::Table.engine = FakeRecord::Base.new

RSpec.describe ToArel do
  it 'has a version number' do
    expect(ToArel::VERSION).not_to be nil
  end

  describe '.parse' do
    describe 'SELECT' do
      # it 'returns an arel select manager' do
      #   expect(ToArel.parse('SELECT 1 FROM posts').class).to eq Arel::SelectManager
      # end

      # it 'has the correct table set' do
      #   expect(ToArel.parse('SELECT 1 FROM posts').froms).to eq [
      #     Arel::Table.new('posts')
      #   ]
      # end

      describe 'to arel and back' do
        it 'parses a simple query' do
          given_sql = 'SELECT id FROM users'
          expected_sql = 'SELECT id FROM "users"'

          expect(ToArel.parse(given_sql).to_sql).to eq expected_sql
        end

        it 'parses a query with an aggregate' do
          given_sql = 'SELECT count(id) FROM users'
          expected_sql = 'SELECT COUNT(id) FROM "users"'

          expect(ToArel.parse(given_sql).to_sql).to eq expected_sql
        end

        it 'parses a query with a subquery' do
          given_sql = 'SELECT id, (SELECT id FROM users LIMIT 1) FROM photos'
          expected_sql = 'SELECT id FROM "photos" INNER JOIN "users" ON "photos"."user_id" = "users"."id"'

          expect(ToArel.parse(given_sql).to_sql).to eq expected_sql
        end

        it 'parses a query with an aggrgate' do
          given_sql = 'SELECT id FROM photos INNER JOIN users ON photos.user_id = users.id'
          expected_sql = 'SELECT id FROM "photos" INNER JOIN "users" ON "photos"."user_id" = "users"."id"'

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
