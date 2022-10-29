FROM ubuntu
WORKDIR /app

RUN \
  apt-get update && \
  apt-get install -y ruby

RUN gem install bundler
COPY Gemfile* /app
RUN bundle install --without development test

COPY . /app
