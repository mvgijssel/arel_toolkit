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
end
