if Gem.loaded_specs.key?('active_record_upsert')
  describe ActiveRecordUpsert do
    class UpsertMiddleware
      def self.call(arel, next_middleware)
        next_middleware.call(arel)
      end
    end

    it 'works for Post.upsert' do
      Arel.middleware.apply([UpsertMiddleware]) do
        post = Post.create!(title: 'some title', content: 'some content')

        expect do
          Post.upsert(id: post.id, title: 'some other title')
        end.to change { post.reload.title }.from('some title').to('some other title')
      end
    end

    it 'works when passing an arel condition' do
      Arel.middleware.apply([UpsertMiddleware]) do
        post = Post.new(id: 1)
        post.title = 'some title'
        post.public = true
        post
          .upsert(attributes: [:title], arel_condition: Post.arel_table[:updated_at].lt(1.day.ago))
      end
    end
  end
end
