# frozen_string_literal: true

class ShortCodeGenerator
  # Build the Base62 alphabet array: ['a', 'b', ..., 'Z', '0', ..., '9']
  # .freeze makes it immutable (best practice for constants)
  BASE62_ALPHABET = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map(&:to_a).flatten.freeze

  DEFAULT_LENGTH = 6

  # Generates a random alphanumeric string
  def self.generate(length = DEFAULT_LENGTH)
    # Create an array of the given length, filling it with random chars from our alphabet, then join them into a string
    Array.new(length) { BASE62_ALPHABET.sample }.join
  end
end
