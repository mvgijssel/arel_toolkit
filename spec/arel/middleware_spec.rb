describe 'Arel.middleware' do
  class ReorderMiddleware
    def self.call(arel, next_middleware)
      arel.query(class: Arel::SelectManager).each do |node|
        orders = node.object.froms.map do |table|
          table[:id].desc
        end

        node.ast.orders.replace(orders)
      end

      next_middleware.call(arel)
    end
  end

  class NoopMiddleware
    def self.call(arel, next_middleware)
      next_middleware.call(arel)
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

    expect(NoopMiddleware)
      .to receive(:call)
      .and_wrap_original do |m, passed_arel, next_middleware|
        expect(passed_arel.object.first).to eq(query_arel)

        m.call(passed_arel, next_middleware)
      end

    Arel.middleware.apply([NoopMiddleware]) do
      query.load
    end
  end

  it 'allows to get the current applied middleware' do
    current = nil

    Arel.middleware.apply([NoopMiddleware]) do
      current = Arel.middleware.current
    end

    expect(current).to eq([NoopMiddleware])
  end

  it 'allows to get the current applied context' do
    expect(NoopMiddleware)
      .to receive(:call)
      .and_wrap_original do |m, arel, next_middleware, passed_context|
      expect(passed_context).to include(yes: :sir)

      m.call(arel, next_middleware)
    end

    Arel.middleware.apply([NoopMiddleware]).context(yes: :sir) do
      expect(Arel.middleware.context).to eq(yes: :sir)

      Post.where(id: 1).load
    end

    expect(Arel.middleware.context).to eq({})
  end

  it 'allows to replace the context with a new context' do
    Arel.middleware.apply([NoopMiddleware]).context(yes: :sir) do
      expect(Arel.middleware.context).to eq(yes: :sir)

      Arel.middleware.context(hello: :friend) do
        expect(Arel.middleware.context).to eq(hello: :friend)
      end
    end
  end

  it 'raises an error when a wrong type is returned from the middleware' do
    class WrongMiddleware
      def self.call(arel, _next_middleware)
        arel
      end
    end

    expect do
      Arel.middleware.apply([WrongMiddleware]) do
        Post.all.load
      end
    end.to raise_error(/returned from middleware needs to be wrapped in `Arel::Middleware::Result`/)
  end

  it 'raises an error when a wrong object is passed to the next middleware' do
    class WrongMiddleware
      def self.call(_arel, next_middleware)
        next_middleware.call('this is not arel')
      end
    end

    expect do
      Arel.middleware.apply([WrongMiddleware]) do
        Post.all.load
      end
    end.to raise_error(/Only `Arel::Enhance::Node` is valid for middleware, passed `String`/)
  end

  it 'sets the original sql in the context' do
    class ChangeMiddleware
      def self.call(_arel, next_middleware)
        next_middleware.call(Arel.enhance(Post.select(:title).arel))
      end
    end

    expect(NoopMiddleware)
      .to receive(:call)
      .and_wrap_original do |m, arel, next_middleware, context|
      expect(arel.to_sql).to eq 'SELECT "posts"."title" FROM "posts"'
      expect(context[:original_sql]).to eq 'SELECT "posts"."content" FROM "posts"'

      m.call(arel, next_middleware)
    end

    Arel.middleware.apply([ChangeMiddleware, NoopMiddleware]) do
      Post.select(:content).load
    end
  end

  it 'does not allow overriding the original sql in the context' do
    expect(NoopMiddleware)
      .to receive(:call)
      .and_wrap_original do |m, arel, next_middleware, context|
      context[:original_sql] = :override

      m.call(arel, next_middleware)
    end

    expect(ReorderMiddleware)
      .to receive(:call)
      .and_wrap_original do |m, arel, next_middleware, context|
      expect(context[:original_sql]).to eq 'SELECT "posts"."content" FROM "posts"'

      m.call(arel, next_middleware)
    end

    Arel.middleware.apply([NoopMiddleware, ReorderMiddleware]) do
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

    Arel.middleware.apply([NoopMiddleware]) do
      Arel.middleware.apply([ReorderMiddleware]) do
        current = Arel.middleware.current
      end
    end

    expect(current).to eq [ReorderMiddleware]
  end

  it 'does not call middleware which is excluded' do
    expect(NoopMiddleware).to_not receive(:call)

    Arel.middleware.apply([NoopMiddleware, ReorderMiddleware]) do
      Arel.middleware.except(NoopMiddleware) do
        expect(Arel.middleware.current).to eq [ReorderMiddleware]

        Post.select(:id).load
      end
    end
  end

  it 'resets middleware when exiting a middleware block' do
    middleware = nil

    Arel.middleware.apply([NoopMiddleware, ReorderMiddleware]) do
      Arel.middleware.except(NoopMiddleware) do
        Post.select(:id).load
      end

      middleware = Arel.middleware.current
    end

    expect(Arel.middleware.current).to eq []
    expect(middleware).to eq [NoopMiddleware, ReorderMiddleware]
  end

  it 'resets middleware next_middleware an exception' do
    expect do
      Arel.middleware.apply([NoopMiddleware]) do
        raise 'something'
      end
    end.to raise_error('something')

    expect(Arel.middleware.current).to eq []
  end

  it 'allows middleware to be inserted before other middleware' do
    middleware = nil

    Arel.middleware.apply([NoopMiddleware]) do
      Arel.middleware.insert_before(ReorderMiddleware, NoopMiddleware) do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([ReorderMiddleware, NoopMiddleware])
  end

  it 'allows middleware to be inserted before all other middleware' do
    middleware = nil

    Arel.middleware.apply([NoopMiddleware]) do
      Arel.middleware.prepend(ReorderMiddleware) do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([ReorderMiddleware, NoopMiddleware])
  end

  it 'allows middleware to be appended after other middleware' do
    middleware = nil

    Arel.middleware.apply([NoopMiddleware]) do
      Arel.middleware.insert_after(ReorderMiddleware, NoopMiddleware) do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([NoopMiddleware, ReorderMiddleware])
  end

  it 'allows middleware to be appended after all middleware' do
    middleware = nil

    Arel.middleware.apply([NoopMiddleware]) do
      Arel.middleware.append(ReorderMiddleware) do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([NoopMiddleware, ReorderMiddleware])
  end

  it 'allows only running specified middleware' do
    middleware = nil

    Arel.middleware.apply([NoopMiddleware]) do
      Arel.middleware.only([ReorderMiddleware]) do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([ReorderMiddleware])
  end

  it 'allows execution without any middleware' do
    middleware = nil

    Arel.middleware.apply([NoopMiddleware]) do
      Arel.middleware.none do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([])
  end

  it 'persists middleware across multiple database connections' do
    middleware = nil

    Arel.middleware.apply([NoopMiddleware]) do
      Post.connection_pool.with_connection do
        middleware = Arel.middleware.current
      end
    end

    expect(middleware).to eq([NoopMiddleware])
  end

  it 'does not change the current middleware when changing the current middleware' do
    middleware = nil

    Arel.middleware.apply([NoopMiddleware]) do
      Arel.middleware.current.push(ReorderMiddleware)
      middleware = Arel.middleware.current
    end

    expect(middleware).to eq([NoopMiddleware])
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
      expect(NoopMiddleware)
        .to receive(:call)
        .and_wrap_original do |m, middleware_arel, next_middleware|
        expect(middleware_arel.to_sql)
          .to eq 'INSERT INTO "posts" ("created_at", "updated_at") VALUES ($1, $2) RETURNING "id"'
        m.call(middleware_arel, next_middleware)
      end

      Arel.middleware.apply([NoopMiddleware]) do
        Post.create!
      end
    end
  end

  it 'calls PostgreSQLAdapter#exec_no_cache' do
    connection = ActiveRecord::Base.connection
    query = Post.where(id: [1, 2]) # IN is not a prepared statement (no cache)

    expect(connection).to receive(:exec_no_cache).and_call_original

    expect(NoopMiddleware)
      .to receive(:call)
      .and_wrap_original do |m, middleware_arel, next_middleware|
      expect(remove_active_record_info(middleware_arel.object.first))
        .to eq remove_active_record_info(query.arel)

      m.call(middleware_arel, next_middleware)
    end

    Arel.middleware.apply([NoopMiddleware]) do
      query.load
    end
  end

  it 'calls PostgreSQLAdapter#exec_cache' do
    connection = ActiveRecord::Base.connection
    query = Post.where(id: 1)

    expect(connection).to receive(:exec_cache).and_call_original
    expect(NoopMiddleware)
      .to receive(:call)
      .and_wrap_original do |m, middleware_arel, next_middleware|
      expect(remove_active_record_info(middleware_arel.object.first))
        .to eq remove_active_record_info(query.arel)

      m.call(middleware_arel, next_middleware)
    end

    Arel.middleware.apply([NoopMiddleware]) do
      query.load
    end
  end

  it 'calls PostgreSQLAdapter#query' do
    connection = ActiveRecord::Base.connection

    expect(connection).to receive(:query).and_call_original
    expect(NoopMiddleware).to receive(:call).and_wrap_original do |m, arel, next_middleware|
      m.call(arel, next_middleware)
    end

    Arel.middleware.apply([NoopMiddleware]) do
      ActiveRecord::Base.connection.indexes('posts')
    end
  end

  it 'has the same SQL before and after middleware for UPDATE' do
    before_sql = []
    after_sql = []

    logger = lambda do |next_arel, next_middleware, context|
      after_sql << next_arel.to_sql
      before_sql << context[:original_sql]
      next_middleware.call(next_arel)
    end

    post = Post.create!

    Arel.middleware.apply([logger]) do
      post.update! title: 'updated title'
    end

    expect(before_sql).to eq [
      'SAVEPOINT active_record_1',
      'UPDATE "posts" SET "title" = $1, "updated_at" = $2 WHERE "posts"."id" = $3',
      'RELEASE SAVEPOINT active_record_1',
    ]

    expect(after_sql).to eq [
      'SAVEPOINT "active_record_1"',
      'UPDATE "posts" SET "title" = $1, "updated_at" = $2 WHERE "posts"."id" = $3',
      'RELEASE SAVEPOINT "active_record_1"',
    ]
  end

  it 'has similar SQL before and after calling middleware for INSERT' do
    before_sql = []
    after_sql = []

    logger = lambda do |next_arel, next_middleware, context|
      after_sql << next_arel.to_sql
      before_sql << context[:original_sql]
      next_middleware.call(next_arel)
    end

    Arel.middleware.apply([logger]) do
      Post.create! title: 't'
    end

    # rubocop:disable Metrics/LineLength
    expect(before_sql).to eq [
      'SAVEPOINT active_record_1',
      'INSERT INTO "posts" ("title", "created_at", "updated_at") VALUES ($1, $2, $3) RETURNING "id"',
      'RELEASE SAVEPOINT active_record_1',
    ]
    expect(after_sql).to eq [
      'SAVEPOINT "active_record_1"',
      'INSERT INTO "posts" ("title", "created_at", "updated_at") VALUES ($1, $2, $3) RETURNING "id"',
      'RELEASE SAVEPOINT "active_record_1"',
    ]
    # rubocop:enable Metrics/LineLength
  end

  it 'has the same SQL before and next_middleware middleware for DELETE' do
    before_sql = []
    after_sql = []

    logger = lambda do |next_arel, next_middleware, context|
      after_sql << next_arel.to_sql
      before_sql << context[:original_sql]
      next_middleware.call(next_arel)
    end

    post = Post.create! title: 't'

    Arel.middleware.apply([logger]) do
      post.destroy!
    end

    expect(before_sql).to eq [
      'SAVEPOINT active_record_1',
      'DELETE FROM "posts" WHERE "posts"."id" = $1',
      'RELEASE SAVEPOINT active_record_1',
    ]
    expect(after_sql).to eq [
      'SAVEPOINT "active_record_1"',
      'DELETE FROM "posts" WHERE "posts"."id" = $1',
      'RELEASE SAVEPOINT "active_record_1"',
    ]
  end

  it 'allows to fetch and remove additional data from the database' do
    add_projection = lambda do |next_arel, next_middleware, _context|
      projections = next_arel.child_at_path([0, 'ast', 'cores', 0, 'projections'])
      new_projection = Post.arel_table[:content]
      projections.replace(projections.object + [new_projection])

      result = next_middleware.call(next_arel)

      column_data = result.remove_column('content')

      expect(column_data).to eq(['some content'])
      expect(result.hash_rows).to eq([{ 'title' => 'some title' }])

      result
    end

    new_post = Post.create! title: 'some title', content: 'some content'

    Arel.middleware.apply([add_projection]) do
      post = Post.all.select(:title).find(new_post.id)
      expect(post.attributes).to eq('id' => nil, 'title' => 'some title')
    end

    post = Post.all.select(:title).find(new_post.id)
    expect(post.attributes).to eq('id' => nil, 'title' => 'some title')
  end

  it 'does not use middleware when configuring a connection to prevent endless checkouts' do
    # New thread makes sure we're not reusing the same connection
    Thread.new do
      # Apply middleware in the new thread otherwise it won't be picked up
      Arel.middleware.apply([NoopMiddleware]) do
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

  it 'works when calling .query with a single argument' do
    Arel.middleware.apply([NoopMiddleware]) do
      expect(ActiveRecord::Base.connection.query('SELECT 1')).to eq [[1]]
    end
  end

  it 'raises an ActiveRecord::StatementInvalid for invalid SQL' do
    expect do
      ActiveRecord::Base.connection.execute('invalid')
    end.to raise_error(ActiveRecord::StatementInvalid)

    Arel.middleware.apply([NoopMiddleware]) do
      expect do
        ActiveRecord::Base.connection.execute('invalid')
      end.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe '#to_sql' do
    it 'returns INSERT SQL for a block without execution' do
      Post.all.delete_all

      sql = Arel.middleware.to_sql(:insert) do
        Post.create!
      end

      expect(Post.all.load).to eq []
      expect(sql).to eq [
        'INSERT INTO "posts" ("created_at", "updated_at") VALUES ($1, $2) RETURNING "id"',
      ]
    end

    it 'returns UPDATE SQL for a block without execution' do
      post = Post.create! title: 'initial title'

      sql = Arel.middleware.to_sql(:update) do
        post.update! title: 'updated title'
      end

      expect(post.reload.title).to eq 'initial title'
      expect(sql).to eq [
        'UPDATE "posts" SET "title" = $1, "updated_at" = $2 WHERE "posts"."id" = $3',
      ]
    end

    it 'returns DELETE SQL for a block without execution' do
      post = Post.create! title: 'initial title'

      sql = Arel.middleware.to_sql(:delete) do
        post.destroy!
      end

      expect(Post.find_by(id: post.id)).to be_present
      expect(sql).to eq [
        'DELETE FROM "posts" WHERE "posts"."id" = $1',
      ]
    end

    it 'returns SELECT SQL for a block without execution' do
      Post.all.delete_all
      Post.create! title: 'some title'
      posts = nil

      sql = Arel.middleware.to_sql(:select) do
        posts = Post.all.load
      end

      expect(posts).to eq []
      expect(sql).to eq ['SELECT "posts".* FROM "posts"']
    end

    it 'works for columns and does not cache the wrong columns' do
      Post.reset_column_information

      sql = Arel.middleware.to_sql(:select) do
        Post.columns
        Post.connection.indexes('posts')
      end

      expect(Post.columns.map(&:name)).to eq %w[
        id
        title
        content
        public
        owner_id
        additional_data
        created_at
        updated_at
      ]

      expect(sql.length).to eq 2
    end
  end
end
