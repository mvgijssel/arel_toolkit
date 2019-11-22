require 'arel'
require 'active_record'
require 'memory_profiler'

require './lib/arel/enhance'
require './lib/arel/extensions'
require './lib/arel/sql_to_arel'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: 'localhost',
  databse: 'arel_toolkit_test',
  username: 'postgres',
)

sql = %{
  SELECT
    posts.id,
    posts.title,
    posts.description,
    posts.permalink,
    users.id,
    users.fullname,
    users.permalink,
    blogs.id,
    blogs.title,
    blogs.permalink
  FROM posts
  INNER JOIN users ON users.id = posts.author_id
  INNER JOIN blogs ON blogs.id = posts.blog_id
}
report = MemoryProfiler.report do
  arel = Arel.sql_to_arel(sql)
  enhanced_arel = Arel.enhance(arel)
end

puts report.pretty_print
