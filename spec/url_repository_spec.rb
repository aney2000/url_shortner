require_relative '../lib/url_repository'

RSpec.describe UrlRepository do
  # 'let' creates a fresh instance of the repository for every single test.
  # This is crucial: it guarantees that data saved in one test doesn't 
  # accidentally leak into the next test and cause false positives.
  let(:repository) { UrlRepository.new }

  describe '#save and #find_by_short_code' do
    it 'stores the long url and retrieves it using the short code' do
      # 1. Action: Save the data
      repository.save('aB3x9', 'https://www.rubylang.org')
      
      # 2. Action: Retrieve the data
      result = repository.find_by_short_code('aB3x9')
      
      # 3. Assertion: Check if it matches
      expect(result).to eq('https://www.rubylang.org')
    end

    it 'returns nil if the short code does not exist in the database' do
      # We look for a code we never saved
      result = repository.find_by_short_code('unknown')
      
      # It should gracefully return nil, not crash
      expect(result).to be_nil
    end
  end
end
