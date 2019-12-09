describe 'Middleware Query Caching' do
  class DummyTransformer
    def call(arel, next_middleware)
      next_middleware.call arel
    end
  end

  let(:next_middleware) { ->(new_arel) { new_arel } }

  it 'stores the result of the middleware transformation' do
    Post.first # Cache warm up

    transformer = DummyTransformer.new

    cache = spy('cache', get: nil, set: nil)

    Arel.middleware.apply([transformer], cache: cache) { Post.first }

    expect(cache).to \
      have_received(:get).with('SELECT  "posts".* FROM "posts" ORDER BY "posts"."id" ASC LIMIT $1')

    expect(cache).to have_received(:set)
  end
end
