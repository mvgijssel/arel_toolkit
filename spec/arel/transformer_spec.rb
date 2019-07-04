describe 'Arel.transformer' do
  it 'works' do
    result = Arel.sql_to_arel('SELECT 1, 2 FROM posts WHERE id = 1')
    # TODO: note we need to pass .ast here, selectmanager should also work
    transformer = Arel::Transformer.call(result.first.ast)

    expect(transformer['cores'][0]['source']['left'].object).to eq Arel::Table.new('posts')
  end
end
