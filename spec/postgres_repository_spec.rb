# frozen_string_literal: true

require_relative '../lib/postgres_repository'
require_relative 'support/shared_repository_contract'

RSpec.describe PostgresRepository do
  let(:conn) { PG.connect(dbname: 'url_shortener_test') }
  let(:repository) { PostgresRepository.new(conn) }

  before(:each) do
    repository.clear!
  end

  after(:all) do
    c = PG.connect(dbname: 'url_shortener_test')
    PostgresRepository.new(c).clear!
    c.close
  end

  it_behaves_like 'a url repository'

  describe 'PostgreSQL-specific behavior' do
    it 'enforces unique short codes' do
      repository.save('abc123', 'https://example.com')

      expect { repository.save('abc123', 'https://other.com') }.to raise_error(PG::UniqueViolation)
    end
  end

  describe '#save_with_user' do
    it 'stores a url associated with a user_id' do
      repository.save_with_user('code1', 'https://example.com', 1)

      result = repository.find_by_short_code('code1')

      expect(result).to eq('https://example.com')
    end
  end

  describe '#find_by_user' do
    it 'returns all urls for a specific user' do
      repository.save_with_user('code1', 'https://example.com', 1)
      repository.save_with_user('code2', 'https://other.com', 1)
      repository.save_with_user('code3', 'https://third.com', 2)

      results = repository.find_by_user(1)

      expect(results.length).to eq(2)
      expect(results.map { |r| r['short_code'] }).to contain_exactly('code1', 'code2')
    end

    it 'returns an empty array when user has no urls' do
      results = repository.find_by_user(999)

      expect(results).to eq([])
    end
  end

  describe '#recent' do
    it 'returns the most recent urls across all users' do
      repository.save_with_user('code1', 'https://first.com', 1)
      repository.save_with_user('code2', 'https://second.com', 2)
      repository.save('code3', 'https://anon.com')

      results = repository.recent(10)

      expect(results.length).to eq(3)
      expect(results.first['short_code']).to eq('code3')
    end

    it 'respects the limit parameter' do
      repository.save('c1', 'https://one.com')
      repository.save('c2', 'https://two.com')
      repository.save('c3', 'https://three.com')

      results = repository.recent(2)

      expect(results.length).to eq(2)
    end
  end
end
