FROM ruby:2.7.7

WORKDIR /app

COPY Gemfile Gemfile.lock arel_toolkit.gemspec /app/
COPY lib/arel_toolkit/version.rb /app/lib/arel_toolkit/
RUN bundle install

COPY . /app
RUN bundle exec rake build

