describe Arel::Transformer::RemoveActiveRecordInfo do
  let(:next_middleware) { ->(arel) { arel } }

  it 'removes the type_caster stored on the Arel::Table' do
    arel = Post.where(id: 1).arel
    arel_table = Arel
      .enhance(arel)
      .child_at_path(['ast', 'cores', 0, 'source', 'left'])
      .object

    new_arel = Arel::Transformer::RemoveActiveRecordInfo.call(arel, next_middleware)
    new_arel_table = Arel
      .enhance(new_arel)
      .child_at_path(['ast', 'cores', 0, 'source', 'left'])
      .object

    expect(arel_table.instance_values.fetch('type_caster'))
      .to be_a_kind_of(ActiveRecord::TypeCaster::Map)

    expect(new_arel_table.instance_values.fetch('type_caster'))
      .to be_nil
  end

  def target_children(arel)
    child_path = ['ast', 'cores', 0, 'wheres', 0, 'children']
    Arel
      .enhance(arel)
      .child_at_path(child_path)
      .object
      .map(&:right)
  end

  it 'replaces the Arel::Nodes::BindParam with the actual value' do
    query = Post.where(content: 'some content', public: true, title: 2.0, locked: false)
    children = target_children(query.arel)

    expect do
      transformed_arel = Arel::Transformer::RemoveActiveRecordInfo.call(query.arel, next_middleware)
      children = target_children(transformed_arel)
    end
      .to change { children }
      .from([
              Post.predicate_builder.build_bind_attribute(:content, 'some content'),
              Post.predicate_builder.build_bind_attribute(:public, true),
              Post.predicate_builder.build_bind_attribute(:title, 2.0),
              Post.predicate_builder.build_bind_attribute(:locked, false),
            ])
      .to([
            Arel::Nodes::Quoted.new('some content'),
            Arel::Nodes::TypeCast.new(Arel::Nodes::Quoted.new('t'), 'bool'),
            Arel::Nodes::Quoted.new('2.0'),
            Arel::Nodes::TypeCast.new(Arel::Nodes::Quoted.new('f'), 'bool'),
          ])
  end

  it 'raises with an unknown BindParam value' do
    arel = Post.where(content: 'some content').arel
    tree = Arel.enhance(arel)
    tree.query(class: ActiveRecord::Relation::QueryAttribute).each do |node|
      node['value_before_type_cast'].replace(Post.arel_table[:id])
    end

    expect do
      Arel::Transformer::RemoveActiveRecordInfo.call(tree.object, next_middleware)
    end.to raise_error(/Unknown value cast/)
  end
end
