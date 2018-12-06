RSpec.describe ToArel do
  it "has a version number" do
    expect(ToArel::VERSION).not_to be nil
  end

  describe '.parse' do
    describe 'SELECT' do
      it 'returns an arel select manager' do
        expect(ToArel.parse('SELECT 1 FROM posts').class).to eq Arel::SelectManager
      end

      it 'has the correct table set' do
        expect(ToArel.parse('SELECT 1 FROM posts').froms).to eq [
          Arel::Table.new('posts'),
        ]
      end
    end

    describe 'UPDATE' do
    end

    describe 'INSERT' do
    end
  end
end
