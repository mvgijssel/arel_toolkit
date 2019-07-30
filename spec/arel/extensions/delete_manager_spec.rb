describe Arel::DeleteManager do
  describe 'equality' do
    it 'equals two update managers' do
      tree1 = Arel::DeleteManager.new.tap { |d| d.from(Arel::Table.new('posts')) }
      tree2 = Arel::DeleteManager.new.tap { |d| d.from(Arel::Table.new('posts')) }

      expect(tree1).to eq(tree2)
    end

    it 'does not equal two update managers' do
      tree1 = Arel::DeleteManager.new.tap { |d| d.from(Arel::Table.new('posts')) }
      tree2 = Arel::DeleteManager.new.tap { |d| d.from(Arel::Table.new('comments')) }

      expect(tree1).to_not eq(tree2)
    end

    it 'works for comparing other objects' do
      tree = Arel::DeleteManager.new.tap { |d| d.from(Arel::Table.new('posts')) }
      other_object = 'foo'

      expect(tree).to_not eq other_object
    end
  end
end
