# URL Shortener

A URL shortening service with user accounts, link history, and containerized deployment.

Built with Ruby, Sinatra, PostgreSQL, Docker.

## Run with Docker

```bash
cp .env.example .env
# Edit .env -- set POSTGRES_USER, POSTGRES_PASSWORD, SESSION_SECRET
docker compose up -d
# Open http://localhost:9292
```

To stop: `docker compose down` (add `-v` to also delete the database).

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
bundle exec rspec             # 84 tests
bundle exec rubocop           # linter
```

## How It Works

1. Visit the app -- you're redirected to **Log In**
2. **Sign Up** with a username (alphanumeric, 1-50 chars) and password (6-72 chars)
3. **Log In** -- you land on the home page
4. Paste a URL, click **Shorten** -- you get a short link
5. If the URL is unreachable, a warning is shown (link is still created)
6. Your **link history** appears below the form
7. Anyone with the short link gets redirected to the original URL
8. `/recent` shows the 20 most recent links from all users (public)

## API

```bash
curl -X POST http://localhost:9292/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'

# {"short_code":"aB3xYz","short_url":"http://localhost:9292/aB3xYz"}
# If URL is unreachable: {"short_code":"...","short_url":"...","warning":"Host is unreachable"}
```

Rate limited to 20 requests/minute per IP.

## Security

- **XSS**: All user data HTML-escaped via `h()` helper
- **SQL injection**: Parameterized queries throughout
- **SSRF**: URL checker blocks private/internal IPs before outbound requests
- **Passwords**: bcrypt hashed, 6-72 char limit enforced
- **Secrets**: `SESSION_SECRET` required in production (raises on boot if missing)
- **Rate limiting**: Login (5/min) and shorten (20/min) per IP
- **CSRF**: Rack::Protection enabled

## Project Structure

```
app.rb                      -- Main app (config, routes, helpers)
routes/auth.rb              -- Signup, login, logout (rate limited)
routes/api.rb               -- JSON API (rate limited)
lib/
  authenticator.rb          -- Register/login with bcrypt, input validation
  postgres_repository.rb    -- URL storage (PostgreSQL, connection pooled)
  user_repository.rb        -- User storage (connection pooled)
  short_code_generator.rb   -- Base62 codes with SecureRandom + collision retry
  url_validator.rb          -- HTTP/HTTPS format validation
  url_checker.rb            -- URL liveness check + SSRF protection
  rate_limiter.rb           -- In-memory per-IP rate limiter
views/                      -- ERB templates + _link_table partial
spec/                       -- 84 RSpec tests
Dockerfile                  -- App container (ruby:3.3-slim)
docker-compose.yml          -- App + PostgreSQL (secrets required via .env)
.github/workflows/ci.yml    -- CI (RuboCop + RSpec with PostgreSQL service)
```
