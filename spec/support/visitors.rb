shared_examples 'pg_node' do |sql, pg_node|
  it "expects `#{pg_node}` to appear in the ast for `#{sql}`" do
    tree = PgQuery.parse(sql).tree
    expect(tree).to pg_ast_contains(Object.const_get(pg_node))
  end
end

shared_examples 'sql_to_arel' do |sql|
  it "expects the sql `#{sql}` to parse the same" do
    parsed_sql = Arel.sql_to_arel(sql).to_sql
    expect(parsed_sql).to eq sql
  end
end

shared_examples 'sql' do |sql, pg_node: nil, sql_to_arel: true|
  visit 'pg_node', sql, pg_node if pg_node
  visit 'sql_to_arel', sql if sql_to_arel
end

shared_examples 'select' do |sql, pg_node: nil, sql_to_arel: true|
  sql = "SELECT #{sql}"
  visit 'pg_node', sql, pg_node if pg_node
  visit 'sql_to_arel', sql if sql_to_arel
end
