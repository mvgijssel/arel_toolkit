describe 'Arel.enhance' do
  it 'uses brackets to access children' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    tree = Arel.enhance(result.first)

    expect(tree['ast']['cores'][0]['source']['left'].object).to eq Arel::Table.new('posts')
  end

  it 'returns the same enhanced AST when the AST is already enhanced' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    tree = Arel.enhance(result.first)

    expect(Arel.enhance(tree)).to eql(tree)
  end

  it 'prints a pretty ast' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    tree = Arel.enhance(result.first)

    verify { tree.inspect }
  end

  it 'prints the same SQL' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    tree = Arel.enhance(result.first)

    expect(tree.to_sql).to eq result.to_sql
  end

  it 'replaces a node using a setter' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    tree = Arel.enhance(result.first)
    old_projections = tree['ast']['cores'][0]['projections']
    new_projections = [3, 4]

    expect do
      old_projections.replace(new_projections)
    end
      .to change { tree.to_sql }
      .from('SELECT 1, 2 FROM "posts" WHERE "id" = 1')
      .to('SELECT 3, 4 FROM "posts" WHERE "id" = 1')
  end

  it 'replaces a node using an instance variable' do
    result = Arel.sql_to_arel('SELECT 1::integer')
    tree = Arel.enhance(result.first)
    old_type_name = tree['ast']['cores'][0]['projections'][0]['type_name']
    new_type_name = 'real'

    expect do
      old_type_name.replace(new_type_name)
    end
      .to change { tree.to_sql }
      .from('SELECT 1::integer')
      .to('SELECT 1::real')
  end

  it 'replaces a node using an array modification' do
    result = Arel.sql_to_arel('SELECT "a", "b"')
    tree = Arel.enhance(result.first)
    old_projection = tree['ast']['cores'][0]['projections'][0]
    new_projection = Arel::Nodes::UnqualifiedColumn.new Arel::Attribute.new(nil, 'c')

    expect do
      old_projection.replace(new_projection)
    end
      .to change { tree.to_sql }
      .from('SELECT "a", "b"')
      .to('SELECT "c", "b"')
  end

  it 'removes a node using an array modification' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    tree = Arel.enhance(result.first)

    expect do
      tree['ast']['cores'][0]['wheres'].remove
      tree['ast']['cores'][0]['projections'][1].remove
    end
      .to change { tree.to_sql }
      .from('SELECT 1, 2 FROM "posts" WHERE "id" = 1')
      .to('SELECT 1 FROM "posts"')
  end

  it 'raises an exception with a hash in the tree' do
    arel = Arel::Attribute.new(Arel::Table.new(:posts), foo: :bar)

    expect do
      Arel.enhance(arel)
    end.to raise_error('Hash is not supported')
  end

  it 'marks a tree as dirty when modified' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    tree = Arel.enhance(result.first)

    expect do
      tree['ast']['cores'][0]['wheres'].remove
    end.to change { tree.dirty? }.from(false).to(true)
  end

  it 'updates the enhanced tree when mutating' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    tree = Arel.enhance(result.first)
    enhanced_nodes = tree.each.to_a
    where_nodes = tree['ast']['cores'][0]['wheres'].remove.each.to_a
    projections_nodes = tree['ast']['cores'][0]['projections'][0].remove.each.to_a

    expect(enhanced_nodes).to all(satisfy { |n| n.root_node == tree.root_node })
    expect(where_nodes).to all(satisfy { |n| n.root_node == tree.root_node })
    expect(projections_nodes).to all(satisfy { |n| n.root_node == tree.root_node })

    expect(where_nodes).to all(satisfy { |n| n.path.to_a.include?('cores') })
    expect(projections_nodes).to all(satisfy { |n| n.path.to_a.include?('cores') })
  end

  it 'returns the partial enhanced tree after mutating' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    tree = Arel.enhance(result.first)
    where_tree = tree['ast']['cores'][0]['wheres'].remove

    expect(where_tree.path.to_a).to eq ['ast', 'cores', 0, 'wheres']
    expect(where_tree.parent.object).to be_a(Arel::Nodes::SelectCore)
  end

  it 'does not change the original arel when replacing' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    tree = Arel.enhance(result.first)
    old_projections = tree['ast']['cores'][0]['projections']
    new_projections = [3, 4]

    expect do
      old_projections.replace(new_projections)
    end.to_not(change { result.to_sql })
  end

  it 'makes a deep copy of the arel when modified' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    original_arel = result.first

    tree = Arel.enhance(original_arel)
    tree['ast']['cores'][0]['source']['left']['name'].replace('comments')
    new_arel = tree.object

    expect(original_arel).to be_not_identical_arel(new_arel)
  end

  it 'does not make a deep copy of the arel if not modified' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    original_arel = result.first

    tree = Arel.enhance(original_arel)
    new_arel = tree.object

    expect(original_arel).to be_identical_arel(new_arel)
  end
end
