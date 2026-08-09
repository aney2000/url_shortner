require_relative '../lib/sqlite_repository'

RSpec.describe SqliteRepository do
  # We pass ':memory:' so each test gets a fresh, isolated, temporary database
  let(:repository) { SqliteRepository.new(':memory:') }

  describe '#save and #find_by_short_code' do
    it 'stores the long url and retrieves it using the short code' do
      repository.save('aB3x9', 'https://www.rubylang.org')
      
      result = repository.find_by_short_code('aB3x9')
      
      expect(result).to eq('https://www.rubylang.org')
    end

    it 'returns nil if the short code does not exist' do
      result = repository.find_by_short_code('unknown')
      
      expect(result).to be_nil
    end
  end
end
