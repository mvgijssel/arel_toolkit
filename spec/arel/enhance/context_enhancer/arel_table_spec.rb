describe Arel::Enhance::ContextEnhancer::ArelTable do
  it 'adds additional context to Arel::Table nodes' do
    result = Arel.sql_to_arel('SELECT posts.id FROM posts')
    original_arel = result.first

    tree = Arel.enhance(original_arel)
    from_table_node = tree.child_at_path(['ast', 'cores', 0, 'source', 'left'])
    projection_table_node = tree.child_at_path(['ast', 'cores', 0, 'projections', 0, 'relation'])

    expect(from_table_node.context).to eq(range_variable: true, column_reference: false)
    expect(projection_table_node.context).to eq(range_variable: false, column_reference: true)
  end

  it 'works for a single table inside FROM' do
    sql = 'SELECT * FROM posts'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)
    table_node = tree.child_at_path(['ast', 'cores', 0, 'source', 'left'])

    expect(table_node.context).to eq(range_variable: true, column_reference: false)
  end

  it 'works for multiple tables inside FROM' do
    sql = 'SELECT * FROM posts, comments'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)

    posts_table_node = tree.child_at_path ['ast', 'cores', 0, 'source', 'left', 0]
    comments_table_node = tree.child_at_path ['ast', 'cores', 0, 'source', 'left', 1]

    expect(posts_table_node.context).to eq(range_variable: true, column_reference: false)
    expect(comments_table_node.context).to eq(range_variable: true, column_reference: false)
  end

  it 'works for joining tables' do
    sql = 'SELECT * FROM posts INNER JOIN comments ON true LEFT JOIN users ON true'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)

    users_table_node = tree.child_at_path ['ast', 'cores', 0, 'source', 'right', 1, 'left']
    comments_table_node = tree.child_at_path ['ast', 'cores', 0, 'source', 'right', 0, 'left']

    expect(users_table_node.context).to eq(range_variable: true, column_reference: false)
    expect(comments_table_node.context).to eq(range_variable: true, column_reference: false)
  end

  it 'works for SELECT projections' do
    sql = 'SELECT posts.id'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)
    attribute_table_node = tree.child_at_path(['ast', 'cores', 0, 'projections', 0, 'relation'])

    expect(attribute_table_node.context).to eq(range_variable: false, column_reference: true)
  end

  it 'works for INSERT INTO table' do
    sql = 'INSERT INTO posts (public) VALUES (true)'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)
    insert_table_node = tree.child_at_path(%w[ast relation])

    expect(insert_table_node.context).to eq(range_variable: true, column_reference: false)
  end

  it 'works for UPDATE table' do
    sql = 'UPDATE posts SET public = TRUE'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)
    update_table_node = tree.child_at_path(%w[ast relation])

    expect(update_table_node.context).to eq(range_variable: true, column_reference: false)
  end

  it 'works for the UPDATE FROM tables' do
    sql = 'UPDATE posts SET public = TRUE FROM users, comments'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)
    users_table_node = tree.child_at_path(['ast', 'froms', 0])
    comments_table_node = tree.child_at_path(['ast', 'froms', 1])

    expect(users_table_node.context).to eq(range_variable: true, column_reference: false)
    expect(comments_table_node.context).to eq(range_variable: true, column_reference: false)
  end

  it 'works for DELETE table' do
    sql = 'DELETE FROM posts'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)
    delete_table_node = tree.child_at_path(%w[ast relation])

    expect(delete_table_node.context).to eq(range_variable: true, column_reference: false)
  end

  it 'works for DELETE USING tables' do
    sql = 'DELETE FROM posts USING users, comments'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)
    users_table_node = tree.child_at_path(['ast', 'using', 0])
    comments_table_node = tree.child_at_path(['ast', 'using', 1])

    expect(users_table_node.context).to eq(range_variable: true, column_reference: false)
    expect(comments_table_node.context).to eq(range_variable: true, column_reference: false)
  end

  it 'works for a CTE table' do
    sql = 'WITH posts AS (SELECT 1) SELECT * FROM posts'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)
    cte_node = tree.child_at_path(['ast', 'with', 'expr', 0, 'left'])

    expect(cte_node.context).to eq(range_variable: false, column_reference: false, alias: true)
  end

  it 'works for a recursive CTE table' do
    sql = 'WITH RECURSIVE posts AS (SELECT 1) SELECT * FROM posts'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)
    cte_node = tree.child_at_path(['ast', 'with', 'expr', 0, 'left'])

    expect(cte_node.context).to eq(range_variable: false, column_reference: false, alias: true)
  end

  it 'works for a SELECT INTO table' do
    sql = 'SELECT INTO public_posts FROM posts WHERE posts.public = TRUE'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)
    into_table_node = tree.child_at_path(['ast', 'cores', 0, 'into', 'expr'])

    expect(into_table_node.context)
      .to eq(range_variable: false, column_reference: false, alias: true)
  end

  it 'raises an error for an arel table in an unknown location' do
    sql = 'SELECT 1'
    tree = Arel.enhance(Arel.sql_to_arel(sql).first)
    limit_node = tree.child_at_path(%w[ast limit])

    expect do
      limit_node.replace(Arel::Table.new('strange_table'))
    end.to raise_error do |error|
      expect(error.message)
        .to include("Unknown AST location for table <Node(Arel::Table) ['ast', 'limit']")
    end
  end
end
