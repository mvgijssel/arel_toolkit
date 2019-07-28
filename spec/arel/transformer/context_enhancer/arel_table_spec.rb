describe Arel::Transformer::ContextEnhancer::ArelTable do
  it 'adds additional context to Arel::Table nodes' do
    result = Arel.sql_to_arel('SELECT posts.id FROM posts')
    original_arel = result.first

    tree = Arel.transformer(original_arel)
    from_table_node = tree.child_at_path(['ast', 'cores', 0, 'source', 'left'])
    projection_table_node = tree.child_at_path(['ast', 'cores', 0, 'projections', 0, 'relation'])

    expect(from_table_node.context).to eq(range_variable: true, column_reference: false)
    expect(projection_table_node.context).to eq(range_variable: false, column_reference: true)
  end

  # TODO: add all cases here :scream:
end
