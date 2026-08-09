class UrlRepository
  def initialize
    # We use a simple Ruby Hash as our "database" for the MVP.
    # It acts as a key-value store looking like this: 
    # { "aB3x9" => "https://google.com" }
    @store = {}
  end

  # Saves the mapping between the short code and the long URL
  def save(short_code, long_url)
    @store[short_code] = long_url
    
    # It is a good Ruby practice to return the identifier of what you just saved
    short_code
  end

  # Retrieves the long URL based on the provided short code
  def find_by_short_code(short_code)
    # If the key exists, it returns the URL. If not, Ruby Hashes naturally return nil.
    @store[short_code]
  end
end
