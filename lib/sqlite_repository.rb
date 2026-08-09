require 'sqlite3'

class SqliteRepository
  # By default, it saves to a file called 'url_shortener.db'
  def initialize(db_file = 'url_shortener.db')
    @db = SQLite3::Database.new(db_file)
    # This tells SQLite to return results as a Hash instead of a plain Array
    @db.results_as_hash = true 
    setup_schema
  end

  def save(short_code, long_url)
    # The '?' are placeholders. This prevents SQL Injection attacks!
    @db.execute("INSERT INTO urls (short_code, long_url) VALUES (?, ?)", [short_code, long_url])
    short_code
  end

  def find_by_short_code(short_code)
    # LIMIT 1 ensures we stop searching once we find it
    result = @db.execute("SELECT long_url FROM urls WHERE short_code = ? LIMIT 1", [short_code])
    
    if result.any?
      result.first['long_url']
    else
      nil
    end
  end

  private

  # This creates the table if it doesn't exist yet
  def setup_schema
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS urls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        short_code TEXT UNIQUE NOT NULL,
        long_url TEXT NOT NULL
      );
    SQL
  end
end
