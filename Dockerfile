FROM ruby:3.3-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential libpq-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set without 'test' && bundle install

COPY . .

EXPOSE 9292

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
    CMD curl -f http://localhost:9292/login || exit 1

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "9292"]
