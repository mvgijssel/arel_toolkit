# typed: false
describe Arel::InsertManager do
  describe 'equality' do
    it 'equals two insert managers' do
      tree1 = Arel::InsertManager.new.tap { |i| i.into(Arel::Table.new('posts')) }
      tree2 = Arel::InsertManager.new.tap { |i| i.into(Arel::Table.new('posts')) }

      expect(tree1).to eq(tree2)
    end

    it 'does not equal two insert managers' do
      tree1 = Arel::InsertManager.new.tap { |i| i.into(Arel::Table.new('posts')) }
      tree2 = Arel::InsertManager.new.tap { |i| i.into(Arel::Table.new('comments')) }

      expect(tree1).to_not eq(tree2)
    end
  end
end