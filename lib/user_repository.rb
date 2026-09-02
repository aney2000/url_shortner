# frozen_string_literal: true

require 'pg'
require 'bcrypt'

class UserRepository
  def initialize(db_pool)
    @db_pool = db_pool
    setup_schema
  end

  def create(username, password)
    password_hash = BCrypt::Password.create(password)
    @db_pool.with do |conn|
      result = conn.exec_params(
        'INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id, username',
        [username, password_hash]
      )
      result[0]
    end
  end

  def find_by_username(username)
    @db_pool.with do |conn|
      result = conn.exec_params(
        'SELECT id, username, password_hash FROM users WHERE username = $1 LIMIT 1',
        [username]
      )
      return nil if result.ntuples.zero?

      result[0]
    end
  end

  private

  def setup_schema
    @db_pool.with do |conn|
      conn.exec(<<-SQL)
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          username TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT NOW()
        );
      SQL
    end
  end
end
