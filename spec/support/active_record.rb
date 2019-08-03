# https://github.com/mvgijssel/arel_toolkit/issues/63
def remove_active_record_info(arel)
  Arel::Transformer::RemoveActiveRecordInfo.call(arel, nil)
end

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: 'localhost',
  databse: 'arel_toolkit_test',
  username: 'postgres',
)

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: :cascade do |t|
    t.string :username

    t.timestamps
  end

  create_table :posts, force: :cascade do |t|
    t.string :title
    t.text :content
    t.boolean :public
    t.integer :owner_id

    t.timestamps
  end
end

class Post < ActiveRecord::Base
  belongs_to :owner, class_name: 'User'
end

class User < ActiveRecord::Base
  has_many :posts, foreign_key: :owner_id
end

ActiveRecord::Base.connection.execute(
  'CREATE OR REPLACE VIEW public_posts AS SELECT * FROM posts WHERE public = true',
)

class PublicPost < ActiveRecord::Base
  self.table_name = :public_posts
end

ActiveRecord::Base.connection.execute(
  'DROP MATERIALIZED VIEW IF EXISTS comments_count; ' \
  'CREATE MATERIALIZED VIEW comments_count AS SELECT COUNT(*) FROM comments',
)

class CommentsCount < ActiveRecord::Base
  self.table_name = :comments_count
end

Arel::Middleware::Railtie.insert_postgresql unless Gem.loaded_specs.key?('railties')
