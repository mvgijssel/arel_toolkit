FROM ruby:2.6

RUN apt-get update ; apt-get install -y nodejs postgresql-client

RUN mkdir -p /app/lib/to_arel
WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version to_arel.gemspec /app/
COPY lib/to_arel/version.rb /app/lib/to_arel/

RUN bundle install -j $(nproc)

