ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: 'localhost',
  databse: 'arel_toolkit_test',
  username: 'postgres',
)

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :posts, force: true do |t|
    t.string :title
    t.text :content
    t.boolean :public

    t.timestamps
  end
end

class Post < ActiveRecord::Base
end

Arel::Middleware::Railtie.insert_postgresql
