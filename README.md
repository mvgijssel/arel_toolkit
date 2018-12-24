# ToArel

## Overview

- [![Build Status](https://travis-ci.com/mvgijssel/to_arel.svg?branch=master)](https://travis-ci.com/mvgijssel/to_arel)
- [![Maintainability](https://api.codeclimate.com/v1/badges/0d47a7de887eca86e136/maintainability)](https://codeclimate.com/github/mvgijssel/to_arel/maintainability)
- [![Test Coverage](https://api.codeclimate.com/v1/badges/0d47a7de887eca86e136/test_coverage)](https://codeclimate.com/github/mvgijssel/to_arel/test_coverage)
- [![Gem Version](https://badge.fury.io/rb/to_arel.svg)](https://badge.fury.io/rb/to_arel)
- [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
- ![](http://ruby-gem-downloads-badge.herokuapp.com/to_arel?type=total)
- ![](http://ruby-gem-downloads-badge.herokuapp.com/to_arel?label=downloads-current-version)

## Usage

Convert your (PostgreSQL) SQL into Arel.

```ruby
[1] > sql = 'SELECT id FROM users;'
=> "SELECT id FROM users;"
[2] > arel = ToArel.parse(sql)
=> #<Arel::SelectManager:0x00007fe4e39823d8>
[3] > arel.to_sql
=> "SELECT \"id\" FROM \"users\""
```

## Contributing

Grab one of our xit-ed specs, fix it, pr it and receive unbound internet point.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'to_arel'
```

And then execute:

```shell
bundle
```

Or install it yourself as:

```shell
gem install to_arel
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ToArel project’s codebases, issue trackers,
chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/[USERNAME]/to_arel/blob/master/CODE_OF_CONDUCT.md).

## Useful links

- [Class definitions postgres](https://doxygen.postgresql.org/)
- [pg_query deparse visitor](https://github.com/lfittl/pg_query/blob/master/lib/pg_query/deparse.rb)
- [pg_query node types](https://github.com/lfittl/pg_query/blob/master/lib/pg_query/node_types.rb)
- [Arel](https://github.com/rails/rails/tree/master/activerecord/lib/arel)
