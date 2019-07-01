describe 'Arel.transformer' do
  it 'works' do
    result = Arel.sql_to_arel('SELECT 1 FROM posts')
    # TODO: note we need to pass .ast here, selectmanager should also work
    transformer = Arel::Transformer.call(result.first.ast)

    expect(transformer['cores']['source']['left'].node).to eq Arel::Table.new('posts')
  end
end
