# URL Shortener

A clean URL shortening service built with Ruby, Sinatra, and PostgreSQL. Features user authentication, per-user link history, and a containerized multi-service architecture.

## Architecture

```
User (browser)
  |
  | port 9292
  v
+-----------------+       +------------------+
|   web container |  -->  |   db container   |
|   (Ruby/Sinatra)|       |   (PostgreSQL)   |
|   port 9292     |       |   port 5432      |
+-----------------+       +------------------+
     backend network (internal)
```

The app follows **clean architecture** with SOLID principles:

- `UrlValidator` -- single responsibility, validates URLs
- `ShortCodeGenerator` -- single responsibility, generates Base62 codes
- `PostgresRepository` -- data access, implements the repository pattern
- `UserRepository` -- user persistence with bcrypt password hashing
- `Authenticator` -- authentication logic, decoupled from HTTP layer

## Quick Start (Docker)

The fastest way to run the app. Requires Docker and Docker Compose.

```bash
# 1. Clone and enter the project
cd url_shortner

# 2. Build and start both containers
docker compose up -d

# 3. Open in your browser
# http://localhost:9292
```

That's it. PostgreSQL starts in its own container, the app connects to it automatically.

To stop:

```bash
docker compose down
```

To stop and delete all data (database volume):

```bash
docker compose down -v
```

## Quick Start (Local Development)

For development without Docker. Requires Ruby, Bundler, and PostgreSQL installed locally.

```bash
# 1. Install dependencies
bundle install

# 2. Create the development database
createdb url_shortener_dev

# 3. Start the server
bundle exec rackup

# 4. Open http://localhost:9292
```

## Running Tests

Tests use a separate `url_shortener_test` database to avoid touching development data.

```bash
# Create the test database (first time only)
createdb url_shortener_test

# Run the full test suite
bundle exec rspec

# Run a specific spec file
bundle exec rspec spec/authenticator_spec.rb

# Run with verbose output
bundle exec rspec --format documentation
```

## Linting

```bash
bundle exec rubocop
```

## Features

### URL Shortening

- Paste a long URL, get a short 6-character Base62 code
- Works for anyone (logged in or anonymous)
- Codes are random, with ~56.8 billion possible combinations

### User Authentication

- **Sign up** at `/signup` with username and password (min 6 chars)
- **Log in** at `/login`
- **Log out** via the nav bar
- Passwords are hashed with bcrypt (never stored in plaintext)

### User Dashboard

- Visit `/dashboard` to see all URLs you have shortened
- Each link shows the short URL and the original long URL
- Only visible when logged in

### Recent Links

- Visit `/recent` to see the 20 most recently shortened URLs
- Public page, visible to everyone

### JSON API

```bash
# Shorten a URL
curl -X POST http://localhost:9292/shorten \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'

# Response (201 Created):
# {"short_code":"aB3xYz","short_url":"http://localhost:9292/aB3xYz"}
```

## Routes

| Method | Path           | Auth     | Description                    |
|--------|----------------|----------|--------------------------------|
| GET    | `/`            | No       | URL shortening form            |
| POST   | `/`            | No       | Shorten a URL (web form)       |
| GET    | `/signup`      | No       | Registration form              |
| POST   | `/signup`      | No       | Create account                 |
| GET    | `/login`       | No       | Login form                     |
| POST   | `/login`       | No       | Authenticate                   |
| POST   | `/logout`      | Yes      | Clear session                  |
| GET    | `/dashboard`   | Yes      | User's link history            |
| GET    | `/recent`      | No       | Global recent links            |
| POST   | `/shorten`     | No       | JSON API endpoint              |
| GET    | `/:short_code` | No       | Redirect to original URL (301) |

## Environment Variables

| Variable          | Default              | Description                    |
|-------------------|----------------------|--------------------------------|
| `DATABASE_NAME`   | `url_shortener_dev`  | PostgreSQL database name       |
| `DATABASE_HOST`   | (unix socket)        | Database host                  |
| `DATABASE_PORT`   | `5432`               | Database port                  |
| `DATABASE_USER`   | (current user)       | Database user                  |
| `DATABASE_PASSWORD` | (none)             | Database password              |
| `SESSION_SECRET`  | (dev default)        | Session cookie secret (64+ chars) |

For production, set `SESSION_SECRET` to a random string:

```bash
openssl rand -hex 32
```

## Docker Services

| Service | Image              | Port  | Purpose          |
|---------|--------------------|-------|------------------|
| `web`   | Built from `./`    | 9292  | Ruby/Sinatra app |
| `db`    | postgres:16-alpine | 5433* | PostgreSQL       |

*Port 5433 is exposed on the host to avoid conflict with a local PostgreSQL. Inside the Docker network, the app connects to `db:5432`.

## Tech Stack

| Component        | Technology         |
|------------------|--------------------|
| Language         | Ruby               |
| Web Framework    | Sinatra            |
| Web Server       | Puma               |
| Database         | PostgreSQL 16      |
| Auth             | bcrypt             |
| Test Framework   | RSpec + Rack::Test |
| Linter           | RuboCop            |
| Containerization | Docker + Compose   |

## Project Structure

```
url_shortner/
  Dockerfile                  -- App container definition
  docker-compose.yml          -- Multi-service orchestration
  Gemfile                     -- Ruby dependencies
  app.rb                      -- Main Sinatra application
  config.ru                   -- Rack boot file
  lib/
    authenticator.rb          -- Login/register logic
    postgres_repository.rb    -- URL persistence (PostgreSQL)
    short_code_generator.rb   -- Base62 code generation
    sqlite_repository.rb      -- Legacy SQLite repository
    url_validator.rb          -- URL validation
    user_repository.rb        -- User persistence
  views/
    index.erb                 -- Home page + shortening form
    login.erb                 -- Login form
    signup.erb                -- Registration form
    dashboard.erb             -- User link history
    recent.erb                -- Global recent links
  public/
    style.css                 -- Stylesheet
  spec/                       -- Test suite (57 tests)
```
