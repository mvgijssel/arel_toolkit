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


    # PgResultInit.create(conn, [Column.new('kerk')])
    PgResultInit.create(conn, [{ name: 'henk' }], [['chulo'], ['shine']])

    binding.pry


    raise 'broken'

  end
end
