FROM ruby:4.0.5-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libpq-dev \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV APP_ENV=development \
    APP_PORT=3000

COPY Gemfile ./
RUN bundle install

COPY bin ./bin

EXPOSE 3000

CMD ["./bin/server"]
