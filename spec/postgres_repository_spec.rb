# frozen_string_literal: true

require_relative '../lib/postgres_repository'

RSpec.describe PostgresRepository do
  let(:repository) { PostgresRepository.new(dbname: 'url_shortener_test') }

  before(:each) do
    repository.clear!
  end

  after(:all) do
    repo = PostgresRepository.new(dbname: 'url_shortener_test')
    repo.clear!
    repo.close
  end

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

    it 'enforces unique short codes' do
      repository.save('abc123', 'https://example.com')

      expect { repository.save('abc123', 'https://other.com') }.to raise_error(PG::UniqueViolation)
    end
  end
end
