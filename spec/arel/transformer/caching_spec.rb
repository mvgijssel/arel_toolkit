describe 'Middleware Query Caching' do
  let(:next_middleware) { ->(new_arel) { new_arel } }

  class MiddlewareOne
    def call(arel, next_middleware)
      next_middleware.call arel
    end
  end

  class MiddlewareTwo
    def call(arel, next_middleware)
      next_middleware.call arel
    end
  end

  it 'stores the result of the middleware transformation' do
    Post.first # Warm up cache

    middleware_one = MiddlewareOne.new
    middleware_two = MiddlewareTwo.new

    cache = spy('cache', get: nil, set: nil)

    Arel.middleware.apply([middleware_one], cache: cache) do
      Arel.middleware.apply([middleware_two]) do
        Post.first
      end
    end

    expect(cache).to \
      have_received(:get).with('SELECT  "posts".* FROM "posts" ORDER BY "posts"."id" ASC LIMIT $1')

    expect(cache).to have_received(:set)
  end
end
