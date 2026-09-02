# URL Shortener

A URL shortening service built with Ruby, Sinatra, and PostgreSQL. Features user authentication, per-user link history, and a containerized multi-service architecture.

## Architecture

```
User (browser :9292)
         |
  [Rack::Protection]       (CSRF, XSS, session hijacking)
         |
    UrlShortenerApp
    |       |       |
Routes::Auth  Routes::Api  Web UI Routes
    |       |       |
    +--- helpers (require_login, current_user) ---+
         |                    |
   Authenticator         ShortCodeGenerator
         |               (collision retry)
   UserRepository       UrlValidator
         |                    |
         +--- [shared PG connection] ---+
                      |
               PostgresRepository
                      |
              [PostgreSQL DB]
```

Each class has a single responsibility. Dependencies are injected. Routes are extracted into modules.

## Quick Start (Docker)

Requires Docker and Docker Compose.

```bash
# Build and start both containers
docker compose up -d

# Open in your browser
# http://localhost:9292
```

PostgreSQL starts in its own container on an internal network. Only port 9292 is exposed.

```bash
# Stop
docker compose down

# Stop and delete all data
docker compose down -v
```

For production, create a `.env` file (see `.env.example`):

```bash
cp .env.example .env
# Edit .env with real values
```

## Quick Start (Local Development)

Requires Ruby, Bundler, and PostgreSQL.

```bash
# Install dependencies
bundle install

# Create the development database
createdb url_shortener_dev

# Start the server
bundle exec rackup

# Open http://localhost:9292
```

## Running Tests

```bash
# Create the test database (first time only)
createdb url_shortener_test

# Run the full suite (66 tests)
bundle exec rspec

# Run a specific file
bundle exec rspec spec/authenticator_spec.rb

# Verbose output
bundle exec rspec --format documentation
```

## Linting

```bash
bundle exec rubocop
```

## Features

### Authentication Required

All URL shortening requires a logged-in user. Anonymous visitors are redirected to `/login`.

### URL Shortening

- Paste a long URL, get a short 6-character Base62 code
- Collision-safe: retries up to 3 times if a duplicate code is generated
- ~56.8 billion possible codes (62^6)

### User Authentication

- **Sign up** at `/signup` with username and password (min 6 chars)
- **Log in** at `/login`
- **Log out** via the nav bar
- Passwords hashed with bcrypt, never stored in plaintext
- Session-cached username (no DB query per page load)

### Link History

- The home page (`/`) shows your shortener form and all your links below
- `/dashboard` also shows your links
- Only your own links are visible

### Recent Links

- `/recent` shows the 20 most recently shortened URLs globally
- Public page, no login required

### JSON API

```bash
curl -X POST http://localhost:9292/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'

# 201 Created
# {"short_code":"aB3xYz","short_url":"http://localhost:9292/aB3xYz"}
```

### Security

- CSRF protection via `Rack::Protection`
- Parameterized SQL queries (no SQL injection)
- bcrypt password hashing
- Session-based auth with secure cookie
- FK constraints on database relations

## Routes

| Method | Path           | Auth | Description                    |
|--------|----------------|------|--------------------------------|
| GET    | `/`            | Yes  | Shortener form + link history  |
| POST   | `/`            | Yes  | Shorten a URL (web form)       |
| GET    | `/signup`      | No   | Registration form              |
| POST   | `/signup`      | No   | Create account                 |
| GET    | `/login`       | No   | Login form                     |
| POST   | `/login`       | No   | Authenticate                   |
| POST   | `/logout`      | Yes  | Clear session                  |
| GET    | `/dashboard`   | Yes  | User's link history            |
| GET    | `/recent`      | No   | Global recent links            |
| POST   | `/shorten`     | No   | JSON API endpoint              |
| GET    | `/:short_code` | No   | Redirect to original URL (301) |

## Environment Variables

| Variable            | Default             | Description                      |
|---------------------|---------------------|----------------------------------|
| `DATABASE_NAME`     | `url_shortener_dev` | PostgreSQL database name         |
| `DATABASE_HOST`     | (unix socket)       | Database host                    |
| `DATABASE_PORT`     | `5432`              | Database port                    |
| `DATABASE_USER`     | (current user)      | Database user                    |
| `DATABASE_PASSWORD` | (none)              | Database password                |
| `SESSION_SECRET`    | (dev default)       | Session cookie secret (64+ chars)|

Generate a production secret:

```bash
openssl rand -hex 32
```

## Docker Services

| Service | Image              | Exposed Port | Purpose          |
|---------|--------------------|--------------|------------------|
| `web`   | Built from `./`    | 9292         | Ruby/Sinatra app |
| `db`    | postgres:16-alpine | (internal)   | PostgreSQL       |

The database is only accessible from the internal `backend` Docker network.

## Tech Stack

| Component        | Technology         |
|------------------|--------------------|
| Language         | Ruby               |
| Web Framework    | Sinatra            |
| Web Server       | Puma               |
| Database         | PostgreSQL 16      |
| Auth             | bcrypt             |
| Security         | Rack::Protection   |
| Test Framework   | RSpec + Rack::Test |
| Linter           | RuboCop            |
| Containerization | Docker + Compose   |
| CI               | GitHub Actions     |

## Project Structure

```
url_shortner/
  .env.example                -- Environment variable template
  .github/workflows/ci.yml   -- CI pipeline (lint + test with PostgreSQL)
  Dockerfile                  -- App container definition
  docker-compose.yml          -- Multi-service orchestration
  Gemfile                     -- Ruby dependencies
  app.rb                      -- Sinatra app (config, helpers, web routes)
  config.ru                   -- Rack boot file
  routes/
    auth.rb                   -- Signup/login/logout routes
    api.rb                    -- JSON API endpoint
  lib/
    authenticator.rb          -- Register/login logic with bcrypt
    postgres_repository.rb    -- URL persistence (PostgreSQL)
    short_code_generator.rb   -- Base62 code generation with collision retry
    url_validator.rb          -- HTTP/HTTPS URL validation
    user_repository.rb        -- User persistence with password hashing
  views/
    layout.erb                -- Shared HTML layout with nav bar
    index.erb                 -- Shortener form + link history
    login.erb                 -- Login form
    signup.erb                -- Registration form
    dashboard.erb             -- User link history
    recent.erb                -- Global recent links
    not_found.erb             -- 404 page
  public/
    style.css                 -- CSS with design tokens and responsive layout
  spec/                       -- 66 tests across 11 spec files
    support/
      shared_repository_contract.rb
```
