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

  it 'replaces a node' do
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

  it 'does not change the original arel when replacing' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    transformer = Arel.transformer(result.first)
    old_projections = transformer['ast']['cores'][0]['projections']
    new_projections = [3, 4]

    expect do
      old_projections.replace(new_projections)
    end.to_not(change { result.to_sql })
  end

  it 'removes a node' do
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
