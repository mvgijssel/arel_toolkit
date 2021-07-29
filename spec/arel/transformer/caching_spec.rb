describe 'Middleware Query Caching' do
  let(:next_middleware) { ->(new_arel) { new_arel } }

  class MiddlewareOne
    def call(arel, next_middleware)
      next_middleware.call arel
    end

    def hash
      'hash_of_middleware_one'
    end
  end

  class MiddlewareTwo
    def call(arel, next_middleware)
      next_middleware.call arel
    end

    def hash
      'hash_of_middleware_two'
    end
  end

  it 'stores the result of the middleware transformation' do
    Post.first # Warm up cache

    middleware_one = MiddlewareOne.new
    middleware_two = MiddlewareTwo.new

    sql = 'SELECT "posts".* FROM "posts" ORDER BY "posts"."id" ASC LIMIT $1'

    allow_any_instance_of(Arel::Middleware::CacheAccessor)
      .to receive(:cache_key_for_sql)
      .with(sql)
      .and_return('sql_cache_key')

    cache = spy('cache', read: nil, write: nil)

    Arel.middleware.apply([middleware_one], cache: cache) do
      Post.first

      expect(cache).to have_received(:read).with('hash_of_middleware_one|sql_cache_key')
      expect(cache).to have_received(:write).with('hash_of_middleware_one|sql_cache_key', sql)
    end

    Arel.middleware.apply([middleware_one, middleware_two], cache: cache) do
      Post.first

      expect(cache).to have_received(:read)
        .with('hash_of_middleware_one&hash_of_middleware_two|sql_cache_key')
      expect(cache).to have_received(:write).with(
        'hash_of_middleware_one&hash_of_middleware_two|sql_cache_key',
        sql,
      )
    end
  end
end
