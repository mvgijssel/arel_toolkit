describe 'Middleware Query Caching' do
  let(:next_middleware) { ->(new_arel) { new_arel } }

  it 'stores the result of the middleware transformation' do
    Post.first # Warm up cache

    transformer = Class.new do
      def call(arel, next_middleware)
        next_middleware.call arel
      end
    end.new

    cache = spy('cache', get: nil, set: nil)

    Arel.middleware.apply([], cache: cache) do
      Arel.middleware.apply([transformer]) { Post.first }
    end

    expect(cache).to \
      have_received(:get).with('SELECT  "posts".* FROM "posts" ORDER BY "posts"."id" ASC LIMIT $1')

    expect(cache).to have_received(:set)
  end
end
