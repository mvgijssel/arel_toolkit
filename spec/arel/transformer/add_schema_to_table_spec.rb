describe Arel::Transformer::AddSchemaToTable do
  it 'works' do
    transformer = Arel::Transformer::AddSchemaToTable.new('secret')
    sql = 'SELECT posts.id FROM posts'
    result = Arel.sql_to_arel(sql)
    new_sql = transformer.call(result.first, nil).to_sql

    expect(new_sql).to eq 'SELECT "posts"."id" FROM "secret"."posts"'
  end
end
