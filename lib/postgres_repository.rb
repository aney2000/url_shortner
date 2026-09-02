# frozen_string_literal: true

require 'pg'

class PostgresRepository
  def initialize(db_pool)
    @db_pool = db_pool
    setup_schema
  end

  def save(short_code, long_url)
    @db_pool.with do |conn|
      conn.exec_params(
        'INSERT INTO urls (short_code, long_url) VALUES ($1, $2)',
        [short_code, long_url]
      )
    end
    short_code
  end

  def save_with_user(short_code, long_url, user_id)
    @db_pool.with do |conn|
      conn.exec_params(
        'INSERT INTO urls (short_code, long_url, user_id) VALUES ($1, $2, $3)',
        [short_code, long_url, user_id]
      )
    end
    short_code
  end

  def find_by_short_code(short_code)
    @db_pool.with do |conn|
      result = conn.exec_params(
        'SELECT long_url FROM urls WHERE short_code = $1 LIMIT 1',
        [short_code]
      )
      return nil if result.ntuples.zero?

      result[0]['long_url']
    end
  end

  def find_by_user(user_id)
    @db_pool.with do |conn|
      result = conn.exec_params(
        'SELECT short_code, long_url, created_at FROM urls WHERE user_id = $1 ORDER BY created_at DESC',
        [user_id]
      )
      result.to_a
    end
  end

  def recent(limit = 10)
    @db_pool.with do |conn|
      result = conn.exec_params(
        'SELECT short_code, long_url, created_at FROM urls ORDER BY created_at DESC LIMIT $1',
        [limit]
      )
      result.to_a
    end
  end

  def clear!
    raise 'clear! is only available in test environment' unless ENV['APP_ENV'] == 'test' || ENV['RACK_ENV'] == 'test'

    @db_pool.with do |conn|
      conn.exec('DELETE FROM urls')
    end
  end

  def close
    @db_pool.shutdown { |conn| conn.close unless conn.finished? }
  end

  private

  def setup_schema
    @db_pool.with do |conn|
      create_urls_table(conn)
      create_indexes(conn)
    end
  end

  def create_urls_table(conn)
    conn.exec(<<-SQL)
      CREATE TABLE IF NOT EXISTS urls (
        id SERIAL PRIMARY KEY,
        short_code TEXT UNIQUE NOT NULL,
        long_url TEXT NOT NULL,
        user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT NOW()
      );
    SQL
  end

  def create_indexes(conn)
    conn.exec('CREATE INDEX IF NOT EXISTS idx_urls_user_id ON urls(user_id);')
    conn.exec('CREATE INDEX IF NOT EXISTS idx_urls_created_at ON urls(created_at DESC);')
  end
end
