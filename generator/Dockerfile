FROM ruby:4.0.5-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libpq-dev \
    libyaml-dev \
    pkg-config \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /generator

COPY Gemfile ./
RUN bundle install

WORKDIR /workspace
