# frozen_string_literal: true

require 'pg'

class PostgresRepository
  def initialize(dbname:, host: nil, port: 5432, user: nil, password: nil)
    conn_params = { dbname: dbname, port: port }
    conn_params[:host] = host if host
    conn_params[:user] = user if user
    conn_params[:password] = password if password

    @conn = PG.connect(conn_params)
    setup_schema
  end

  def save(short_code, long_url)
    @conn.exec_params(
      'INSERT INTO urls (short_code, long_url) VALUES ($1, $2)',
      [short_code, long_url]
    )
    short_code
  end

  def save_with_user(short_code, long_url, user_id)
    @conn.exec_params(
      'INSERT INTO urls (short_code, long_url, user_id) VALUES ($1, $2, $3)',
      [short_code, long_url, user_id]
    )
    short_code
  end

  def find_by_short_code(short_code)
    result = @conn.exec_params(
      'SELECT long_url FROM urls WHERE short_code = $1 LIMIT 1',
      [short_code]
    )
    return nil if result.ntuples.zero?

    result[0]['long_url']
  end

  def find_by_user(user_id)
    result = @conn.exec_params(
      'SELECT short_code, long_url, created_at FROM urls WHERE user_id = $1 ORDER BY created_at DESC',
      [user_id]
    )
    result.to_a
  end

  def recent(limit = 10)
    result = @conn.exec_params(
      'SELECT short_code, long_url, created_at FROM urls ORDER BY created_at DESC LIMIT $1',
      [limit]
    )
    result.to_a
  end

  def clear!
    @conn.exec('DELETE FROM urls')
  end

  def close
    @conn.close unless @conn.finished?
  end

  private

  def setup_schema
    @conn.exec(<<-SQL)
      CREATE TABLE IF NOT EXISTS urls (
        id SERIAL PRIMARY KEY,
        short_code TEXT UNIQUE NOT NULL,
        long_url TEXT NOT NULL,
        user_id INTEGER,
        created_at TIMESTAMP DEFAULT NOW()
      );
    SQL
  end
end
