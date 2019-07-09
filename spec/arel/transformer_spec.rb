describe 'Arel.transformer' do
  it 'uses brackets to access children' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    transformer = Arel.transformer(result.first)

    expect(transformer['ast']['cores'][0]['source']['left'].object).to eq Arel::Table.new('posts')
  end

  it 'returns a transformer when it is already a transformer' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    transformer = Arel.transformer(result.first)

    expect(Arel.transformer(transformer)).to eql(transformer)
  end

  it 'prints a pretty ast' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    transformer = Arel.transformer(result.first)

    verify { transformer.inspect }
  end

  it 'prints the same SQL' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    transformer = Arel.transformer(result.first)

    expect(transformer.to_sql).to eq result.to_sql
  end

  it 'replaces a node using a setter' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    transformer = Arel.transformer(result.first)
    old_projections = transformer['ast']['cores'][0]['projections']
    new_projections = [3, 4]

    expect do
      old_projections.replace(new_projections)
    end
      .to change { transformer.to_sql }
      .from('SELECT 1, 2 FROM "posts" WHERE "id" = 1')
      .to('SELECT 3, 4 FROM "posts" WHERE "id" = 1')
  end

  it 'replaces a node using an instance variable' do
    result = Arel.sql_to_arel('SELECT 1::integer')
    transformer = Arel.transformer(result.first)
    old_type_name = transformer['ast']['cores'][0]['projections'][0]['type_name']
    new_type_name = 'real'

    expect do
      old_type_name.replace(new_type_name)
    end
      .to change { transformer.to_sql }
      .from('SELECT 1::integer')
      .to('SELECT 1::real')
  end

  it 'replaces a node using an array modification' do
    result = Arel.sql_to_arel('SELECT "a", "b"')
    transformer = Arel.transformer(result.first)
    old_projection = transformer['ast']['cores'][0]['projections'][0]
    new_projection = Arel::Nodes::UnboundColumnReference.new('"c"')

    expect do
      old_projection.replace(new_projection)
    end
      .to change { transformer.to_sql }
      .from('SELECT "a", "b"')
      .to('SELECT "c", "b"')
  end

  it 'removes a node using an array modification' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    transformer = Arel.transformer(result.first)

    expect do
      transformer['ast']['cores'][0]['wheres'].remove
      transformer['ast']['cores'][0]['projections'][1].remove
    end
      .to change { transformer.to_sql }
      .from('SELECT 1, 2 FROM "posts" WHERE "id" = 1')
      .to('SELECT 1 FROM "posts"')
  end

  it 'does not change the original arel when replacing' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    transformer = Arel.transformer(result.first)
    old_projections = transformer['ast']['cores'][0]['projections']
    new_projections = [3, 4]

    expect do
      old_projections.replace(new_projections)
    end.to_not(change { result.to_sql })
  end

  it 'makes a deep copy of the arel when modified' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    original_arel = result.first

    transformer = Arel.transformer(original_arel)
    transformer['ast']['cores'][0]['source']['left']['name'].replace('comments')
    new_arel = transformer.object

    expect(original_arel).to be_not_identical_arel(new_arel)
  end

  it 'does not make a deep copy of the arel if not modified' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    original_arel = result.first

    transformer = Arel.transformer(original_arel)
    new_arel = transformer.object

    expect(original_arel).to be_identical_arel(new_arel)
  end
end
