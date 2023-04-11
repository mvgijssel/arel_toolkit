FROM ruby:3.2

WORKDIR /app

ENV RUBY_YJIT_ENABLE=1

COPY Gemfile Gemfile.lock arel_toolkit.gemspec /app/
COPY lib/arel_toolkit/version.rb /app/lib/arel_toolkit/
RUN bundle install

COPY . /app
RUN bundle exec rake build

