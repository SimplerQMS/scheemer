FROM ruby:3.2-alpine

RUN apk add --no-cache --update git build-base

WORKDIR /usr/src/app

RUN gem install bundler

COPY . .

RUN bundle install
