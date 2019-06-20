describe 'Arel.middleware' do
  class SomeMiddleware
    def self.call(arel)
      arel
    end
  end

  class OtherMiddleware
    def self.call(arel)
      arel
    end
  end

  it 'calls the middleware before executing the SQL query' do
    query = Post.where(id: 7)
    query_arel = replace_active_record_arel(query.arel)
    middleware_sql = nil

    expect(SomeMiddleware)
      .to receive(:call)
      .and_wrap_original do |m, passed_arel|
        expect(passed_arel).to eq(query_arel)

        m.call(passed_arel)
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
    begin
      Arel.middleware.apply([SomeMiddleware]) do
        raise 'something'
      end
    rescue StandardError => e
    end

    expect(e.message).to eq 'something'
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
    expect_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      .to receive(:execute).twice.and_call_original

    expect_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      .to receive(:execute_without_arel_middleware).twice.and_call_original

    Post.create!
  end

  it 'calls PostgreSQLAdapter#exec_no_cache' do
    expect_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      .to receive(:exec_no_cache).twice.and_call_original

    expect_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      .to receive(:exec_no_cache_without_arel_middleware).twice.and_call_original

    Post.where(id: [1, 2]).load # IN statements are not prepared

    ActiveRecord::Base.connection.unprepared_statement do
      Post.where(id: 1).load
    end
  end

  it 'calls PostgreSQLAdapter#exec_cache' do
    expect_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      .to receive(:exec_cache).and_call_original

    expect_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      .to receive(:exec_cache_without_arel_middleware).and_call_original

    Post.where(id: 1).load
  end
end
