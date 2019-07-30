describe Arel::Transformer::AddSchemaToTable do
  it 'adds the given schema name to all range variable tables' do
    transformer = Arel::Transformer::AddSchemaToTable.new('secret')
    sql = 'SELECT posts.id FROM posts INNER JOIN comments ON comments.post_id = posts.id'
    result = Arel.sql_to_arel(sql)
    new_sql = transformer.call(result.first, nil).to_sql

    expect(new_sql)
      .to eq 'SELECT "posts"."id" FROM "secret"."posts" INNER JOIN "secret"."comments" ' \
             'ON "comments"."post_id" = "posts"."id"'
  end

  it 'does not override existing schema name' do
    transformer = Arel::Transformer::AddSchemaToTable.new('secret')
    sql = 'SELECT posts.id FROM posts INNER JOIN public.comments ON comments.post_id = posts.id'
    result = Arel.sql_to_arel(sql)
    new_sql = transformer.call(result.first, nil).to_sql

    expect(new_sql)
      .to eq 'SELECT "posts"."id" FROM "secret"."posts" INNER JOIN "public"."comments" ' \
             'ON "comments"."post_id" = "posts"."id"'
  end
end
