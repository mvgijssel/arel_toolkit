shared_examples 'pg_node' do |sql, pg_node|
  it "expects `#{pg_node}` to appear in the ast for `#{sql}`" do
    tree = PgQuery.parse(sql).tree
    expect(tree).to pg_ast_contains(Object.const_get(pg_node))
  end
end

shared_examples 'sql_to_arel' do |sql, expected_sql|
  it "expects the sql `#{sql}` to parse the same" do
    expected_sql ||= sql
    parsed_sql = Arel.sql_to_arel(sql).to_sql
    expect(parsed_sql).to eq expected_sql
  end
end

shared_examples 'enhance' do |sql|
  it "expects the sql `#{sql}` to work with the enhanced AST" do
    parsed_sql = Arel.sql_to_arel(sql)
    parsed_sql.each do |sql_part|
      Arel.enhance(sql_part)
    end
  end
end

shared_examples 'all' do |sql, *args, pg_node: nil, sql_to_arel: true, expected_sql: nil|
  raise "Unknown argument(s) `#{args.inspect}`" unless args.length.zero?

  visit 'pg_node', sql, pg_node if pg_node
  visit 'sql_to_arel', sql, expected_sql if sql_to_arel
  visit 'enhance', sql if sql_to_arel
end

shared_examples 'sql' do |sql, *args, **kwargs|
  visit 'all', sql, *args, **kwargs
end

shared_examples 'select' do |sql, *args, **kwargs|
  sql = "SELECT #{sql}"
  visit 'all', sql, *args, **kwargs
end
