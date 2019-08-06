describe Arel::Nodes::Exists do
  it 'implements the as method' do
    node = Arel::Nodes::Exists.new(1)
    node.as('some_alias')

    expect(node.alias).to eq(Arel.sql('some_alias'))
  end

  it 'implements the hash method so only selected variables in the hash function' do
    node1 = Arel::Nodes::Exists.new(1)
    node1.instance_variable_set(:@other_var, 2)
    node2 = Arel::Nodes::Exists.new(1)

    expect(node1.hash).to eq node2.hash
  end

  it 'implements the eql? method so only selected variables in the eql function' do
    node1 = Arel::Nodes::Exists.new(1)
    node1.instance_variable_set(:@other_var, 2)
    node2 = Arel::Nodes::Exists.new(1)

    expect(node1).to eq node2
  end
end
