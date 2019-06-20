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

## sql_to_arel

Convert your (PostgreSQL) SQL into Arel.

```ruby
[1] > sql = 'SELECT id FROM users'
=> "SELECT id FROM users;"
[2] > arel = Arel.sql_to_arel(sql)
=> #<Arel::SelectManager:0x00007fe4e39823d8>
[3] > arel.to_sql
=> "SELECT \"id\" FROM \"users\""
```

## Extensions

Adds some missing Arel nodes and extends the existing visitors.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/arel_toolkit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ArelToolkit project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/arel_toolkit/blob/master/CODE_OF_CONDUCT.md).
