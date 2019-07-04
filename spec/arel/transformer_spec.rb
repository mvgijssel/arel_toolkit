describe 'Arel.transformer' do
  it 'uses brackets to access children' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')

    transformer = Arel::Transformer.call(result.first)

    expect(transformer['ast']['cores'][0]['source']['left'].object).to eq Arel::Table.new('posts')
  end
end
