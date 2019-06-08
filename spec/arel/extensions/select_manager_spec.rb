describe Arel::SelectManager do
  describe 'equality' do
    it 'equals two select managers' do
      tree1 = Arel::SelectManager.new(Arel::Table.new('posts'))
      tree2 = Arel::SelectManager.new(Arel::Table.new('posts'))

      expect(tree1).to eq(tree2)
    end

    it 'does not equal two select managers' do
      tree1 = Arel::SelectManager.new(Arel::Table.new('posts'))
      tree2 = Arel::SelectManager.new(Arel::Table.new('comments'))

      expect(tree1).to_not eq(tree2)
    end
  end
end
