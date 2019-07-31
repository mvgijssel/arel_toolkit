describe Arel::Enhance::Query do
  it 'works for a node context' do
    sql = 'SELECT 1 FROM posts'
    tree = Arel.transformer(Arel.sql_to_arel(sql).first)
    table_node = tree.child_at_path(['ast', 'cores', 0, 'source', 'left'])

    expect(tree.query(context: table_node.context)).to eq [table_node]
  end

  it 'works quering only a subset of the context' do
    sql = 'SELECT 1 FROM posts'
    tree = Arel.transformer(Arel.sql_to_arel(sql).first)
    table_node = tree.child_at_path(['ast', 'cores', 0, 'source', 'left'])

    expect(tree.query(context: { range_variable: true })).to eq [table_node]
  end

  it 'works for a node parent' do
    sql = 'SELECT 1 FROM posts'
    tree = Arel.transformer(Arel.sql_to_arel(sql).first)
    table_node = tree.child_at_path(['ast', 'cores', 0, 'source', 'left'])

    expect(tree.query(parent: { object: { class: Arel::Nodes::JoinSource } }).first)
      . to eq table_node
  end

  it 'works node object attributes' do
    sql = 'SELECT 1 FROM posts'
    tree = Arel.transformer(Arel.sql_to_arel(sql).first)
    table_node = tree.child_at_path(['ast', 'cores', 0, 'source', 'left'])

    expect(tree.query(name: 'posts', relpersistence: 'p')). to eq [table_node]
  end

  it 'searches from the current node, not from the root_node' do
    sql = 'SELECT 1 FROM posts WHERE public = TRUE'
    tree = Arel.transformer(Arel.sql_to_arel(sql).first)
    table_node = tree.child_at_path(['ast', 'cores', 0, 'source', 'left'])
    where_node = tree.child_at_path(['ast', 'cores', 0, 'wheres'])

    expect(tree.query(class: Arel::Table, name: 'posts')).to eq [table_node]
    expect(where_node.query(class: Arel::Table, name: 'posts')).to eq []
  end

  it 'does not break when comparing incompatible objects' do
    sql = 'SELECT 1 FROM posts LIMIT 10'
    tree = Arel.transformer(Arel.sql_to_arel(sql).first)

    expect(tree.query(class: Arel::Nodes::Limit, expr: [1])).to eq []
  end

  it 'does not break when searching for unknown attributes' do
    sql = 'SELECT 1 FROM posts'
    tree = Arel.transformer(Arel.sql_to_arel(sql).first)

    expect(tree.query(klass: Arel::Table)).to eq []
  end
end
