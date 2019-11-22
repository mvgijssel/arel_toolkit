
describe Arel::Transformer::AttributesWithTable do
  let(:next_middleware) { ->(new_arel) { new_arel } }

  it do
    transformer = described_class.new
    sql = 'SELECT "posts"."id" FROM "posts"'

    prefixed_sql = transformer.call(
      Arel.sql_to_arel(sql).first,
      next_middleware,
    ).to_sql

    expect(prefixed_sql).to eq 'SELECT "posts"."id" FROM "posts" WHERE "posts"."id" > 1'
  end

  it do
    transformer = described_class.new
    sql = 'SELECT "id" FROM "posts" INNER JOIN "users" ON "users"."id" = "user_id" WHERE "id" > 1'

    prefixed_sql = transformer.call(
      Arel.sql_to_arel(sql).first,
      next_middleware,
    ).to_sql

    expect(prefixed_sql).to eq 'SELECT "posts"."id" FROM "posts" WHERE "posts"."id" > 1'
  end

  it do
    transformer = described_class.new
    sql = 'SELECT "id" FROM "posts" WHERE "id" > 1'

    prefixed_sql = transformer.call(
      Arel.sql_to_arel(sql).first,
      next_middleware,
    ).to_sql

    expect(prefixed_sql).to eq 'SELECT "posts"."id" FROM "posts" WHERE "posts"."id" > 1'
  end
end
