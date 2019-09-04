describe ArelToolkit do
  it 'has a version number' do
    expect(ArelToolkit::VERSION).not_to be nil
  end

  it 'extension' do
    class Column
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end

    conn = ActiveRecord::Base.connection.raw_connection

    binding.pry

    PgResultInit.create(conn, [Column.new('kerk')])
  end
end
