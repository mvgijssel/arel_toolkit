describe Arel::SqlToArel::PgQueryVisitor do
  describe 'accept' do
    it 'raises nice exceptions for all unknown errors' do
      sql = 'SELECT posts.id AS id FROM posts'

      parser = described_class.new
      message = <<~STRING
        SQL: #{sql}
        BINDS: []
        message: uh oh
      STRING

      expect(parser).to receive(:visit_ResTarget).and_wrap_original do |_m, *_args|
        raise 'uh oh'
      end

      expect do
        parser.accept(sql)
      end.to raise_error do |error|
        expect(error.message).to eq message
      end
    end
  end
end
