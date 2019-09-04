# bundle exec gdb -q -ex 'set breakpoint pending on' -ex 'b malloc_error_break' -ex run --args ruby debug_script.rb

=begin
Get the current ruby backtrace in gdb:

call (void) rb_backtrace()


=end

GC.disable

require 'bundler/setup'
require 'pry'
require 'pry-alias'
require 'arel_toolkit'

require_relative './spec/support/active_record'
# require 'rails_helper' if Gem.loaded_specs.key?('rspec-rails')


def do_it(run_number)

  puts "RUN NUMBER: #{run_number}"

  add_projection = lambda do |next_arel, next_middleware, _context|
    projections = next_arel.child_at_path([0, 'ast', 'cores', 0, 'projections'])
    new_projection = Post.arel_table[:content]
    projections.replace(projections.object + [new_projection])

    result = next_middleware.call(next_arel)

    column_data = result.remove_column('content')

    puts column_data
    # expect(column_data).to eq(['some content'])
    puts result.hash_rows
    # expect(result.hash_rows).to eq([{ 'id' => 0, 'title' => 'some title' }])

    result
  end

  new_post = Post.create! title: 'some title', content: 'some content'

  Arel.middleware.apply([add_projection]) do
    post = Post.all.select(:id, :title).where(id: new_post.id)
    puts post.map(&:attributes)
    # expect(post.attributes).to eq('id' => 0, 'title' => 'some title')
  end

  post = Post.all.select(:id, :title).where(id: new_post.id)
  puts post.map(&:attributes)
  # expect(post.attributes).to eq('id' => 0, 'title' => 'some title')

  puts "\n\n\n\n\n"
end


100.times do |run_number|
  do_it run_number
end
