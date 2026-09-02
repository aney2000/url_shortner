# URL Shortener

A URL shortening service with user accounts, link history, and containerized deployment.

Built with Ruby, Sinatra, PostgreSQL, Docker.

## Run with Docker

```bash
docker compose up -d
# Open http://localhost:9292
```

To stop: `docker compose down` (add `-v` to also delete the database).

For production, copy `.env.example` to `.env` and set real values.

## Run Locally

Requires Ruby, Bundler, PostgreSQL.

```bash
bundle install
createdb url_shortener_dev
bundle exec rackup
# Open http://localhost:9292
```

## Tests

```bash
createdb url_shortener_test   # first time only
bundle exec rspec             # 66 tests
bundle exec rubocop           # linter
```

## How It Works

1. Visit the app -- you're redirected to **Log In**
2. **Sign Up** with a username and password
3. **Log In** -- you land on the home page
4. Paste a URL, click **Shorten** -- you get a short link
5. Your **link history** appears below the form
6. Anyone with the short link gets redirected to the original URL
7. `/recent` shows the 20 most recent links from all users (public)

## API

```bash
curl -X POST http://localhost:9292/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'

# {"short_code":"aB3xYz","short_url":"http://localhost:9292/aB3xYz"}
```

## Project Structure

```
app.rb                      -- Main app (config, routes, helpers)
routes/auth.rb              -- Signup, login, logout
routes/api.rb               -- JSON API
lib/
  authenticator.rb          -- Register/login with bcrypt
  postgres_repository.rb    -- URL storage (PostgreSQL)
  user_repository.rb        -- User storage
  short_code_generator.rb   -- Base62 codes with collision retry
  url_validator.rb          -- HTTP/HTTPS validation
views/                      -- ERB templates (layout, index, login, signup, dashboard, recent, 404)
spec/                       -- 66 RSpec tests
Dockerfile                  -- App container
docker-compose.yml          -- App + PostgreSQL orchestration
.github/workflows/ci.yml    -- CI (RuboCop + RSpec with PostgreSQL service)
```
