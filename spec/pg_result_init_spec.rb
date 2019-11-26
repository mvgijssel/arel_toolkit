describe PgResultInit do
  let(:conn) { ActiveRecord::Base.connection.raw_connection }
  let(:original_result) do
    ActiveRecord::Base.connection.execute "SELECT 1 AS a, '2' as b, TRUE as c, NULL as d"
  end

  it 'creates a new PG::Result based on another result' do
    columns = [{ name: 'hello', typid: 0, typlen: 0 }]

    rows = [%w[friend]]

    new_result = PgResultInit.create(conn, original_result, columns, rows)

    expect(new_result.to_a).to eq([{ 'hello' => 'friend' }])
  end

  it 'returns the correct data from the result helper methods' do
    columns = [
      { name: 'hello', tableid: 2, columnid: 3, format: 1, typid: 4, typlen: 5, atttypmod: 6 }
    ]

    rows = [%w[friend]]

    new_result = PgResultInit.create(conn, original_result, columns, rows)

    expect(new_result.fname(0)).to eq 'hello'
    expect(new_result.ftable(0)).to eq 2
    expect(new_result.ftablecol(0)).to eq 3
    expect(new_result.fformat(0)).to eq 1
    expect(new_result.ftype(0)).to eq 4
    expect(new_result.fsize(0)).to eq 5
    expect(new_result.fmod(0)).to eq 6
  end

  it 'handles nil values in the rows' do
    columns = [{ name: 'hello', typid: 0, typlen: 0 }]

    rows = [[nil], [1]]

    new_result = PgResultInit.create(conn, original_result, columns, rows)

    expect(new_result.field_values('hello')).to eq [nil, '1']
  end

  it 'handles invalid column input' do
    columns = 1

    rows = []

    expect { PgResultInit.create(conn, original_result, columns, rows) }.to raise_error(TypeError)
  end

  it 'handles invalid column value input' do
    columns = ['not a hash']

    rows = []

    expect { PgResultInit.create(conn, original_result, columns, rows) }.to raise_error(TypeError)
  end

  it 'handles invalid column value member input', aggregate_failures: true do
    columns = [{ name: ['not a string'], typid: 0, typlen: 0 }]

    rows = []

    expect { PgResultInit.create(conn, original_result, columns, rows) }.to raise_error(
      TypeError,
      /implicit conversion of Array into String/
    )

    columns = [{ name: 'hello', typid: 'not an integer', typlen: 0 }]

    rows = []

    expect { PgResultInit.create(conn, original_result, columns, rows) }.to raise_error(
      TypeError,
      /implicit conversion of String into Integer/
    )
  end

  it 'raises when missing a required column field' do
    columns = [{ name: 'hello', typlen: 0 }]

    rows = []

    expect { PgResultInit.create(conn, original_result, columns, rows) }.to raise_error(KeyError)
  end

  it 'handles invalid row input' do
    columns = [{ name: 'hello', typid: 0, typlen: 0 }]

    rows = 'not an array'

    expect { PgResultInit.create(conn, original_result, columns, rows) }.to raise_error(TypeError)
  end

  it 'handles invalid connection input' do
    columns = [{ name: 'hello', typid: 0, typlen: 0 }]

    rows = []
    conn = false

    expect { PgResultInit.create(conn, original_result, columns, rows) }.to raise_error(
      TypeError,
      /expected kind of PG::Connection/
    )
  end

  it 'handles invalid result input' do
    columns = [{ name: 'hello', typid: 0, typlen: 0 }]

    rows = []
    original_result = OpenStruct.new(id: 1)

    expect { PgResultInit.create(conn, original_result, columns, rows) }.to raise_error(
      TypeError,
      /expected kind of PG::Result/
    )
  end

  it 'handles when there are uneven excess column values' do
    columns = [{ name: 'hello', typid: 0, typlen: 0 }]

    rows = [%w[foo], ['should be', 'one item']]

    new_result = PgResultInit.create(conn, original_result, columns, rows)

    expect(new_result.to_a).to eq [{ 'hello' => 'foo' }, { 'hello' => 'should be' }]
  end

  it 'handles when there are not enough column values rows' do
    columns = [{ name: 'hello', typid: 0, typlen: 0 }, { name: 'friend', typid: 0, typlen: 0 }]

    rows = [['not enough']]

    new_result = PgResultInit.create(conn, original_result, columns, rows)

    expect(new_result.to_a).to eq [{ 'hello' => 'not enough', 'friend' => nil }]
  end

  it 'sets tableid to 0 when not given' do
    columns = [{ name: 'hello', typid: 0, typlen: 0 }]

    rows = []

    new_result = PgResultInit.create(conn, original_result, columns, rows)

    expect(new_result.ftable(0)).to eq 0
  end

  it 'sets columnid to 0 when not given' do
    columns = [{ name: 'hello', typid: 0, typlen: 0 }]

    rows = []

    new_result = PgResultInit.create(conn, original_result, columns, rows)

    expect(new_result.ftablecol(0)).to eq 0
  end

  it 'sets format to 0 when not given' do
    columns = [{ name: 'hello', typid: 0, typlen: 0 }]

    rows = []

    new_result = PgResultInit.create(conn, original_result, columns, rows)

    expect(new_result.fformat(0)).to eq 0
  end

  it 'sets atttypmod to -1 when not given' do
    columns = [{ name: 'hello', typid: 0, typlen: 0 }]

    rows = []

    new_result = PgResultInit.create(conn, original_result, columns, rows)

    expect(new_result.fmod(0)).to eq(-1)
  end
end
