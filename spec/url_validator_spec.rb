require_relative '../lib/url_validator'

RSpec.describe UrlValidator do
  describe '.valid?' do
    it 'returns true for a valid https URL' do
      expect(UrlValidator.valid?('https://www.google.com')).to be true
    end

    it 'returns true for a valid http URL' do
      expect(UrlValidator.valid?('http://example.com')).to be true
    end

    it 'returns false for a random string' do
      expect(UrlValidator.valid?('hello_i_am_a_random_text')).to be false
    end

    it 'returns false if the protocol (http/https) is missing' do
      expect(UrlValidator.valid?('www.google.com')).to be false
    end
  end
end
