FROM ruby:3.2.2-alpine AS word

RUN apk --update add \
    build-base \
    tzdata \
    libc6-compat \
    && rm -rf /var/cache/apk/*

WORKDIR /app

COPY Gemfile* /app/
RUN gem update --system 3.5.10
RUN gem install bundler -v $(tail -n 1 Gemfile.lock)
RUN bundle check || bundle install

COPY . /app/

ENTRYPOINT ["./docker-entrypoint.sh"]