describe Arel::TreeManager do
  describe 'each' do
    it 'allows to enumerate all the children' do
      tree = Arel::TreeManager.new
      arel = Arel.sql_to_arel('SELECT 1').first
      tree.instance_variable_set(:@ast, arel.ast)

      expect { |b| tree.each(&b) }.to yield_control.exactly(16).times
    end

    it 'allows to chain enurable methods' do
      tree = Arel::TreeManager.new
      arel = Arel.sql_to_arel('SELECT 1').first
      tree.instance_variable_set(:@ast, arel.ast)

      expect(tree.each.to_a.last).to eq arel.ast
    end
  end
end
