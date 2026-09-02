# frozen_string_literal: true

class ShortCodeGenerator
  BASE62_ALPHABET = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map(&:to_a).flatten.freeze
  DEFAULT_LENGTH = 6
  MAX_RETRIES = 3

  def self.generate(length = DEFAULT_LENGTH)
    Array.new(length) { BASE62_ALPHABET.sample }.join
  end

  def self.generate_unique(repository, length = DEFAULT_LENGTH)
    MAX_RETRIES.times do
      code = generate(length)
      return code unless repository.find_by_short_code(code)
    end
    raise "Failed to generate unique short code after #{MAX_RETRIES} attempts"
  end
end
