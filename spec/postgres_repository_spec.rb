# frozen_string_literal: true

require_relative '../lib/postgres_repository'
require_relative '../lib/user_repository'
require_relative 'support/shared_repository_contract'

RSpec.describe PostgresRepository do
  let(:conn) { PG.connect(dbname: 'url_shortener_test') }
  let(:user_repo) { UserRepository.new(conn) }
  let(:repository) { PostgresRepository.new(conn) }

  before(:each) do
    repository.clear!
    conn.exec('DELETE FROM users')
  end

  after(:all) do
    c = PG.connect(dbname: 'url_shortener_test')
    c.exec('DELETE FROM urls')
    c.exec('DELETE FROM users')
    c.close
  end

  def create_user(username)
    user_repo.create(username, 'password123')
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
      user = create_user('alice')
      repository.save_with_user('code1', 'https://example.com', user['id'])

      result = repository.find_by_short_code('code1')

      expect(result).to eq('https://example.com')
    end
  end

  describe '#find_by_user' do
    it 'returns all urls for a specific user' do
      user1 = create_user('alice')
      user2 = create_user('bob')
      repository.save_with_user('code1', 'https://example.com', user1['id'])
      repository.save_with_user('code2', 'https://other.com', user1['id'])
      repository.save_with_user('code3', 'https://third.com', user2['id'])

      results = repository.find_by_user(user1['id'])

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
      user1 = create_user('alice')
      user2 = create_user('bob')
      repository.save_with_user('code1', 'https://first.com', user1['id'])
      repository.save_with_user('code2', 'https://second.com', user2['id'])
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
