describe Arel::Transformer::RemoveActiveRecordInfo do
  it 'removes the type_caster stored on the Arel::Table' do
    arel = Post.where(id: 1).arel
    arel_table = Arel
      .enhance(arel)
      .child_at_path(['ast', 'cores', 0, 'source', 'left'])
      .object

    new_arel = Arel::Transformer::RemoveActiveRecordInfo.call(arel, nil)
    new_arel_table = Arel
      .enhance(new_arel)
      .child_at_path(['ast', 'cores', 0, 'source', 'left'])
      .object

    expect(arel_table.instance_values.fetch('type_caster'))
      .to be_a_kind_of(ActiveRecord::TypeCaster::Map)

    expect(new_arel_table.instance_values.fetch('type_caster'))
      .to be_nil
  end

  it 'replaces the Arel::Nodes::BindParam with the actual value' do
    query = Post.where(content: 'some content')
    child_path = ['ast', 'cores', 0, 'wheres', 0, 'children', 0, 'right']
    bind_param = Arel
      .enhance(query.arel)
      .child_at_path(child_path)
      .object

    new_arel = Arel::Transformer::RemoveActiveRecordInfo.call(query.arel, nil)
    new_arel_param = Arel
      .enhance(new_arel)
      .child_at_path(child_path)
      .object

    expect(bind_param).to be_a_kind_of(Arel::Nodes::BindParam)
    expect(new_arel_param).to be_a_kind_of(Arel::Nodes::Quoted)

    expect(query.to_sql).to eq(new_arel.to_sql)
  end
end
