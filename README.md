# Ruby URL Shortener MVP

A lightweight, fully tested URL shortener built with Ruby and Sinatra. This project strictly adheres to **Clean Architecture** and **SOLID principles**, completely decoupling the core business logic from the web framework and database layers.

## Features

- **Web Interface:** A clean HTML/CSS frontend for human users.
- **JSON API:** Endpoints for programmatic access and external integrations.
- **Persistent Storage:** SQLite3 integration using the Repository Pattern.
- **High Test Coverage:** Comprehensive unit and integration tests using RSpec and Rack::Test.
- **CI/CD Ready:** Automated linting (RuboCop) and testing via GitHub Actions.

## Architecture

This application uses the **Dependency Inversion Principle**. The core components (`UrlValidator`, `ShortCodeGenerator`) do not know anything about Sinatra or SQLite. Data persistence is handled via a `SqliteRepository` contract, which means the database can be swapped out in the future without touching a single line of business logic.

## Prerequisites

- Ruby (v3.0 or higher recommended)
- Bundler (`gem install bundler`)
- SQLite3 installed on your system

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd ruby_shortener
   ```

2. **Install dependencies:**
   ```bash
   bundle install
   ```

3. **Start the web server:**
   ```bash
   bundle exec rackup -s puma -p 4567
   ```
   *The SQLite database (`production.db`) will be created automatically on the first run.*

4. **Access the application:**
   Open your browser and navigate to `http://localhost:4567`.

## API Usage

You can also interact with the application programmatically via the JSON API.

**Create a short URL:**
```bash
curl -X POST http://localhost:4567/shorten \
     -H "Content-Type: application/json" \
     -d '{"url": "[https://www.ruby-lang.org](https://www.ruby-lang.org)"}'
```

**Response:**
```json
{
  "short_code": "aB3x9",
  "short_url": "http://localhost:4567/aB3x9"
}
```

## Testing & Linting

This project uses RSpec for Test-Driven Development (TDD) and RuboCop for code styling.

**Run the test suite:**
```bash
bundle exec rspec
```

**Run the linter:**
```bash
bundle exec rubocop
```
