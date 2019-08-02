describe 'Arel.middleware' do
  class SomeMiddleware
    def self.call(arel, _context)
      arel
    end
  end

  class OtherMiddleware
    def self.call(arel, _context)
      arel
    end
  end

  before do
    # This makes sure ActiveRecord preloads index, columns, etc
    # So these requests don't show up as middleware calls
    Post.create!
    Post.where(id: 0).load
  end

  it 'calls the middleware before executing the SQL query' do
    query = Post.where(id: 7)
    query_arel = remove_active_record_info(query.arel)
    query.instance_variable_set(:@arel, query_arel)

    middleware_sql = nil

    expect(SomeMiddleware)
      .to receive(:call)
      .and_wrap_original do |m, passed_arel, context|
        expect(passed_arel).to eq(query_arel)

        m.call(passed_arel, context)
      end

    Arel.middleware.apply([SomeMiddleware]) do
      middleware_sql = query.load.to_sql
    end

    expect(middleware_sql).to eq query.to_sql
  end

  it 'allows to get the current applied middleware' do
    current = nil

    Arel.middleware.apply([SomeMiddleware]) do
      current = Arel.middleware.current
    end

    expect(current).to eq([SomeMiddleware])
  end

  it 'allows to get the current applied context' do
    context = nil

    Arel.middleware.apply([SomeMiddleware]).context(yes: :sir) do
      context = Arel.middleware.context

      expect(SomeMiddleware).to receive(:call).and_wrap_original do |m, arel, passed_context|
        expect(passed_context).to include(yes: :sir)
        m.call(arel, passed_context)
      end

      Post.where(id: 1).load
    end

    expect(context).to eq(yes: :sir)
  end

  it 'allows to replace the context with a new context' do
    Arel.middleware.apply([SomeMiddleware]).context(yes: :sir) do
      expect(Arel.middleware.context).to eq(yes: :sir)

      Arel.middleware.context(hello: :friend) do
        expect(Arel.middleware.context).to eq(hello: :friend)
      end
    end
  end

  it 'sets the original sql in the context' do
    class ChangeMiddleware
      def self.call(_arel, _context)
        Post.select(:title).arel
      end
    end

    expect(SomeMiddleware).to receive(:call).and_wrap_original do |m, arel, context|
      expect(arel.to_sql)
        .to eq 'SELECT "posts"."title" FROM "posts"'
      expect(context[:original_sql])
        .to eq 'SELECT "posts"."content" FROM "posts"'

      m.call(arel, context)
    end

    Arel.middleware.apply([ChangeMiddleware, SomeMiddleware]) do
      Post.select(:content).load
    end
  end

  it 'does not allow overriding the original sql in the context' do
    expect(SomeMiddleware).to receive(:call).and_wrap_original do |m, arel, context|
      context[:original_sql] = :override

      m.call(arel, context)
    end

    expect(OtherMiddleware).to receive(:call).and_wrap_original do |m, arel, context|
      expect(context[:original_sql]).to eq 'SELECT "posts"."content" FROM "posts"'

      m.call(arel, context)
    end

    Arel.middleware.apply([SomeMiddleware, OtherMiddleware]) do
      Post.select(:content).load
    end
  end

  it 'raises an exception when calling context with a block wihout arguments' do
    expect do
      Arel.middleware.context {}
    end.to raise_error('You cannot do a block statement while calling context without arguments')
  end

  it 'only applies middleware given for a block' do
    current = nil

    Arel.middleware.apply([SomeMiddleware]) do
      Arel.middleware.apply([OtherMiddleware]) do
        current = Arel.middleware.current
      end
    end

    expect(current).to eq [OtherMiddleware]
  end

  it 'does not call middleware which is excluded' do
    expect(SomeMiddleware).to_not receive(:call)
    expect(OtherMiddleware).to receive(:call).and_call_original

    Arel.middleware.apply([SomeMiddleware, OtherMiddleware]) do
      Arel.middleware.except(SomeMiddleware) do
        Post.select(:id).load
      end
    end
  end

  it 'resets middleware when exiting a middleware block' do
    middleware = nil

    Arel.middleware.apply([SomeMiddleware, OtherMiddleware]) do
      Arel.middleware.except(SomeMiddleware) do
        Post.select(:id).load
      end

      middleware = Arel.middleware.current
    end

    expect(Arel.middleware.current).to eq []
    expect(middleware).to eq [SomeMiddleware, OtherMiddleware]
  end

  it 'resets middleware after an exception' do
    expect do
      Arel.middleware.apply([SomeMiddleware]) do
        raise 'something'
      end
    end.to raise_error('something')

    expect(Arel.middleware.current).to eq []
  end

  it 'allows middleware to be inserted before other middleware' do
    middleware = nil

    Arel.middleware.apply([SomeMiddleware]) do
      Arel.middleware.insert_before(OtherMiddleware, SomeMiddleware) do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([OtherMiddleware, SomeMiddleware])
  end

  it 'allows middleware to be appended after other middleware' do
    middleware = nil

    Arel.middleware.apply([SomeMiddleware]) do
      Arel.middleware.insert_after(OtherMiddleware, SomeMiddleware) do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([SomeMiddleware, OtherMiddleware])
  end

  it 'allows only running specified middleware' do
    middleware = nil

    Arel.middleware.apply([SomeMiddleware]) do
      Arel.middleware.only([OtherMiddleware]) do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([OtherMiddleware])
  end

  it 'allows execution without any middleware' do
    middleware = nil

    Arel.middleware.apply([SomeMiddleware]) do
      Arel.middleware.none do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([])
  end

  it 'persists middleware across multiple database connections' do
    middleware = nil

    Arel.middleware.apply([SomeMiddleware]) do
      Post.connection_pool.with_connection do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([SomeMiddleware])
  end

  it 'does not change the current middleware when changing the current middleware' do
    middleware = nil

    Arel.middleware.apply([SomeMiddleware]) do
      Arel.middleware.current.push(OtherMiddleware)
      middleware = Arel.middleware.current
    end

    expect(middleware).to eq([SomeMiddleware])
  end

  it 'does not parse SQL when no middleware is present' do
    expect(Arel).to_not receive(:sql_to_arel)

    Arel.middleware.none do
      Post.where(id: 1).load
    end
  end

  it 'calls PostgreSQLAdapter#execute' do
    connection = ActiveRecord::Base.connection

    Post.transaction(requires_new: true) do
      expect(connection).to receive(:execute).and_call_original
      expect(SomeMiddleware).to receive(:call).and_wrap_original do |m, middleware_arel, context|
        expect(middleware_arel.to_sql)
          .to eq 'INSERT INTO "posts" ("created_at", "updated_at") VALUES ($1, $2) RETURNING "id"'
        m.call(middleware_arel, context)
      end

      Arel.middleware.apply([SomeMiddleware]) do
        Post.create!
      end
    end
  end

  it 'calls PostgreSQLAdapter#exec_no_cache' do
    connection = ActiveRecord::Base.connection
    query = Post.where(id: [1, 2]) # IN is not a prepared statement (no cache)

    expect(connection).to receive(:exec_no_cache).and_call_original
    expect(SomeMiddleware).to receive(:call).and_wrap_original do |m, middleware_arel, context|
      expect(remove_active_record_info(middleware_arel)).to eq remove_active_record_info(query.arel)

      m.call(middleware_arel, context)
    end

    Arel.middleware.apply([SomeMiddleware]) do
      query.load
    end
  end

  it 'calls PostgreSQLAdapter#exec_cache' do
    connection = ActiveRecord::Base.connection
    query = Post.where(id: 1)

    expect(connection).to receive(:exec_cache).and_call_original
    expect(SomeMiddleware).to receive(:call).and_wrap_original do |m, middleware_arel, context|
      expect(remove_active_record_info(middleware_arel)).to eq remove_active_record_info(query.arel)

      m.call(middleware_arel, context)
    end

    Arel.middleware.apply([SomeMiddleware]) do
      query.load
    end
  end

  it 'calls PostgreSQLAdapter#query' do
    connection = ActiveRecord::Base.connection

    expect(connection).to receive(:query).and_call_original
    expect(SomeMiddleware).to receive(:call).and_call_original

    Arel.middleware.apply([SomeMiddleware]) do
      ActiveRecord::Base.connection.indexes('posts')
    end
  end

  it 'has the same SQL before and after middleware for UPDATE' do
    post = Post.create!(title: 'some title', content: 'some content', public: false)

    expect(ActiveRecord::Base.connection)
      .to receive(:exec_no_cache)
      .and_wrap_original do |m, sql, name, binds|
      middleware_sql = Arel::Middleware.current_chain.execute(sql, binds)

      expect(middleware_sql).to eq(sql)

      m.call(sql, name, binds)
    end

    Arel.middleware.apply([SomeMiddleware]) do
      post.update title: nil, content: nil, public: true
    end
  end

  it 'has the same SQL before and after middleware for INSERT' do
    expect(ActiveRecord::Base.connection)
      .to receive(:exec_no_cache)
      .and_wrap_original do |m, sql, name, binds|
      middleware_sql = Arel::Middleware.current_chain.execute(sql, binds)

      expect(middleware_sql).to eq(sql)

      m.call(sql, name, binds)
    end

    Arel.middleware.apply([SomeMiddleware]) do
      Post.create!(title: 'some title', content: 'some content')
    end
  end

  it 'has the same SQL before and after middleware for DELETE' do
    post = Post.create!(title: 'some title', content: 'some content')

    expect(ActiveRecord::Base.connection)
      .to receive(:exec_no_cache)
      .and_wrap_original do |m, sql, name, binds|
      middleware_sql = Arel::Middleware.current_chain.execute(sql, binds)

      expect(middleware_sql).to eq(sql)

      m.call(sql, name, binds)
    end

    Arel.middleware.apply([SomeMiddleware]) do
      post.destroy!
    end
  end

  it 'does not use middleware when configuring a connection to prevent endless checkouts' do
    # New thread makes sure we're not reusing the same connection
    Thread.new do
      # Apply middleware in the new thread otherwise it won't be picked up
      Arel.middleware.apply([SomeMiddleware]) do
        # Force checkout a new connection
        ActiveRecord::Base.connection_pool.with_connection do
          Post.create!(title: 'some title', content: 'some content')
        end
      end
    end.join
  end

  it 'raises an error when middleware calls middleware to prevent endless recursion' do
    class RecursiveMiddleware
      def self.call(_arel, _context)
        Post.first
      end
    end

    Arel.middleware.apply([RecursiveMiddleware]) do
      expect { Post.first }
        .to raise_error(/Middleware is being called from within middleware, aborting execution/)
    end
  end
end
