# ArelToolkit

## Overview

- [![Build Status](https://travis-ci.com/mvgijssel/arel_toolkit.svg?branch=master)](https://travis-ci.com/mvgijssel/arel_toolkit)
- [![Maintainability](https://api.codeclimate.com/v1/badges/3ef13d1649a00a98562d/maintainability)](https://codeclimate.com/github/mvgijssel/arel_toolkit/maintainability)
- [![Test Coverage](https://api.codeclimate.com/v1/badges/3ef13d1649a00a98562d/test_coverage)](https://codeclimate.com/github/mvgijssel/arel_toolkit/test_coverage)
- [![Gem Version](https://badge.fury.io/rb/arel_toolkit.svg)](https://badge.fury.io/rb/arel_toolkit)
- [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
- ![](http://ruby-gem-downloads-badge.herokuapp.com/arel_toolkit?type=total)
- ![](http://ruby-gem-downloads-badge.herokuapp.com/arel_toolkit?label=downloads-current-version)
- [Coverage report](https://mvgijssel.github.io/arel_toolkit/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'arel_toolkit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install arel_toolkit

## Sql to Arel

Convert your (PostgreSQL) SQL into an Arel AST.

```ruby
[1] > sql = 'SELECT id FROM users'
=> "SELECT id FROM users;"
[2] > arel = Arel.sql_to_arel(sql)
=> #<Arel::SelectManager:0x00007fe4e39823d8>
[3] > arel.to_sql
=> "SELECT \"id\" FROM \"users\""
```

## Extensions

This gem aims to have full support for PostgreSQL's SQL. In order to do so, it needs to add missing Arel nodes and extends the existing visitors. A full list of extensions on Arel can be found here: [lib/arel/extensions](https://github.com/mvgijssel/arel_toolkit/tree/master/lib/arel/extensions).

## Middleware

Creating Arel from SQL is just the beginning, where this gem really shines is the ability to modify Arel ASTs using middleware.

Middleware sits between ActiveRecord and the database, it allows you to alter the Arel (the SQL query) before it's send to the database. Multiple middlewares are supported by passing the results from a finished middleware to the next. Next to the arel object, a context object is used that acts as a intermediate storage between middlewares.

The middleware works out of the box in combination with Rails. If using ActiveRecord standalone you need to run the following **after** setting up the database connection:

```ruby
Arel::Middleware::Railtie.insert_postgresql
```

### Example

Create some middleware (this can be any Ruby object as long as it responds to `call`). In this example, we're creating a middleware that will reorder any query. Next to reordering, we're adding an additional middleware that prints out the result of the reorder middleware.

```ruby
class ReorderMiddleware
  def self.call(arel, _context)
    arel.order(Post.arel_table[:id].asc)
  end
end

class LoggingMiddleware
  def self.call(arel, context)
    puts "User executing query: `#{context[:current_user_id]}`"
    puts "Original SQL: `#{context[:original_sql]}`"
    puts "Modified SQL: `#{arel.to_sql}`"
    
    arel
  end
end
```

Now that we've defined our middelwares, it's time to see them in action: 

```ruby
[1] > Arel.middleware.apply([ReorderMiddleware, LoggingMiddleware]).context(current_user_id: 1) { Post.all.load }
User executing query: `1`
Original SQL: `SELECT "posts".* FROM "posts" ORDER BY "posts"."id" DESC`
Modified SQL: `SELECT "posts".* FROM "posts" ORDER BY "posts"."id" DESC, "posts"."id" ASC`
Post Load (4.1ms)  SELECT "posts".* FROM "posts" ORDER BY "posts"."id" DESC, "posts"."id" ASC
=> []
```

This gem ships with a couple of middelware methods that allow you to fine-tune what and when to apply middelware.
- `Arel.middleware.apply([SomeMiddleware]) { ... }`
- `Arel.middleware.only([OnlyMe]) { ... }`
- `Arel.middleware.none { ... }`
- `Arel.middleware.except(RemoveMe) { ... }`
- `Arel.middleware.insert_before(RunBefore, ThisMiddleware) { ... }`
- `Arel.middleware.insert_after(RunAfter, ThisMiddleware) { ... }`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mvgijssel/arel_toolkit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ArelToolkit project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mvgijssel/arel_toolkit/blob/master/CODE_OF_CONDUCT.md).
