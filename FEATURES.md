# URL Shortener - Feature Documentation

## Overview

A URL shortening service built with **Ruby**, **Sinatra**, and **PostgreSQL**.
Provides a web UI for browser users and a JSON API for programmatic access.
Containerized with Docker for production deployment.

---

## Architecture

```
Sinatra App (app.rb / config.ru)
  |
  |-- Web UI         GET /  |  POST /
  |-- JSON API       POST /shorten
  |-- Auth           GET/POST /signup, /login, /logout
  |-- Redirect       GET /:short_code
  |
  |-- Business Logic
  |     |-- UrlValidator       (format validation)
  |     |-- UrlChecker         (liveness check + SSRF protection)
  |     |-- ShortCodeGenerator (Base62 codes, SecureRandom)
  |     |-- Authenticator      (registration + login, bcrypt)
  |     |-- RateLimiter        (per-IP request throttling)
  |
  |-- Persistence
        |-- PostgresRepository (URL storage, connection pooled)
        |-- UserRepository     (user accounts, connection pooled)
```

---

## Security Features

- **XSS prevention**: Auto-escaped ERB output (`escape_html: true`)
- **SQL injection protection**: Parameterized queries throughout
- **SSRF protection**: UrlChecker blocks requests to private/internal IPs
- **Password hashing**: bcrypt with 72-byte limit enforcement
- **Session security**: Rack::Protection enabled, secret required in production
- **Rate limiting**: Per-IP throttling on login (5/min) and shorten (20/min)
- **Input validation**: URL format, username format (alphanumeric, 1-50 chars)

## Tech Stack

| Component        | Technology         |
|------------------|--------------------|
| Language         | Ruby 3.3           |
| Web Framework    | Sinatra 4.x        |
| Web Server       | Puma               |
| Database         | PostgreSQL 16      |
| DB Pooling       | connection_pool     |
| Auth             | bcrypt              |
| Template Engine  | ERB (auto-escaped)  |
| Test Framework   | RSpec + Rack::Test  |
| Linter           | RuboCop             |
| CI/CD            | GitHub Actions      |
| Deployment       | Docker + Compose    |
