describe Arel::Transformer::ReplaceTableWithSubquery do
  let(:next_middleware) { ->(new_arel) { new_arel } }

  it 'works as middleware' do
    # Make sure ActiveRecord is loaded
    Post.create!
    Post.where(id: 0).load

    transformer =
      Arel::Transformer::ReplaceTableWithSubquery.new(->(_) { Post.where('public = TRUE').arel })

    query = Post.all
    middleware_sql = nil
    query_sql = query.to_sql

    Arel.middleware.apply([transformer]) do
      expect(Arel.middleware.executor).to receive(:run)
        .and_wrap_original do |m, enhanced_arel, context, final_block|
        wrapped_final_block = lambda do |processed_sql, processed_binds|
          middleware_sql = processed_sql

          final_block.call(processed_sql, processed_binds)
        end
        m.call(enhanced_arel, context, wrapped_final_block)
      end

      query.load
    end

    expect(query_sql).to eq 'SELECT "posts".* FROM "posts"'
    expect(
      middleware_sql
    ).to eq 'SELECT "posts".* FROM (SELECT "posts".* FROM "posts" WHERE (public = TRUE)) posts'
  end

  context 'table' do
    it 'does not replace when no mapping is present' do
      transformer = Arel::Transformer::ReplaceTableWithSubquery.new(->(_) {  })
      sql = 'SELECT "posts"."id" FROM "posts"'
      arel = Arel.sql_to_arel(sql)
      transformed_sql = transformer.call(arel.first, next_middleware).to_sql

      expect(transformed_sql).to eq 'SELECT "posts"."id" FROM "posts"'
    end
  end
end
