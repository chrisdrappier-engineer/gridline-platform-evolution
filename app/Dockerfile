FROM ruby:4.0.5-slim AS base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      libpq-dev \
      libvips42 \
      libyaml-dev \
      pkg-config \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

EXPOSE 3000

FROM base AS development

ENV RAILS_ENV=development \
    RAILS_LOG_TO_STDOUT=true

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]

FROM base AS production

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_WITHOUT="development:test"

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile

CMD ["bin/thrust", "bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
