describe 'Arel.middleware' do
  class SomeMiddleware
    def self.call(arel)
      arel
    end
  end

  it 'calls the middleware before executing the SQL query' do
    query = Post.where(id: 7)
    arel = query.arel
    middleware_sql = nil

    expect(SomeMiddleware)
      .to receive(:call)
      .and_wrap_original do |m, passed_arel|
        # TODO: why doesn't eq work for a SelectManager?
        expect(passed_arel.ast).to eq(arel.ast)

        m.call(passed_arel)
      end

    Arel.middleware.apply([SomeMiddleware]).models([Post]) do
      middleware_sql = query.load.to_sql
    end

    expect(middleware_sql).to eq query.to_sql
  end

  it 'allows to get the current applied middleware' do
    Arel.middleware.apply([SomeMiddleware]) do
      expect(Arel.middleware.current).to eq [SomeMiddleware]
    end
  end

  it 'allows to get the current applied context' do
    Arel.middleware.apply([SomeMiddleware]).context(yes: :sir) do
      expect(Arel.middleware.context).to eq(yes: :sir)
    end
  end

  it 'allows to replace the context with a new context' do
    Arel.middleware.apply([SomeMiddleware]).context(yes: :sir) do
      expect(Arel.middleware.context).to eq(yes: :sir)

      Arel.middleware.context.replace(hello: :friend) do
        expect(Arel.middleware.context).to eq(hello: :friend)
      end
    end
  end

  it 'allows to merge the existing context with new values' do
    Arel.middleware.apply([SomeMiddleware]).context(yes: :sir) do
      expect(Arel.middleware.context).to eq(yes: :sir)

      Arel.middleware.context.merge(hello: :friend) do
        expect(Arel.middleware.context).to eq(hello: :friend, yes: :sir)
      end
    end
  end

  it 'allows to merge the existing context using a shorthand' do
    Arel.middleware.apply([SomeMiddleware]).context(yes: :sir) do
      expect(Arel.middleware.context).to eq(yes: :sir)

      Arel.middleware.context(hello: :friend) do
        expect(Arel.middleware.context).to eq(hello: :friend, yes: :sir)
      end
    end
  end

  it 'only executes applied middleware given for a block' do
  end

  it 'does not call middleware which is excluded' do
  end

  it 'resets middleware when exiting a middleware block' do
  end

  it 'resets middleware after an exception' do
  end

  it 'allows middleware to be inserted before other middleware' do
  end

  it 'allows middleware to be appended after other middleware' do
  end

  it 'allows only running specified middleware' do
  end

  it 'allows execution without any middleware' do
  end

  it 'throws an exception with the same middleware added twice' do
  end

  it 'persists middleware across multiple database connections' do
  end

  it 'does not change the current middleware when changing the current middleware' do
  end

  it 'handles removed bind values' do
  end
end
