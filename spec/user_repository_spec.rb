# frozen_string_literal: true

require_relative '../lib/user_repository'

RSpec.describe UserRepository do
  let(:pool) { test_db_pool }
  let(:repository) { UserRepository.new(pool) }

  before(:each) do
    repository
    pool.with { |conn| conn.exec('DELETE FROM users') }
  end

  after(:all) do
    c = test_db_connection
    c.exec('DELETE FROM users') rescue nil # rubocop:disable Style/RescueModifier
    c.close
  end

  describe '#create' do
    it 'creates a user and returns the user hash with id' do
      user = repository.create('alice', 'securepass123')

      expect(user['id']).not_to be_nil
      expect(user['username']).to eq('alice')
      expect(user).not_to have_key('password_hash')
    end

    it 'raises an error when username already exists' do
      repository.create('alice', 'password1')

      expect { repository.create('alice', 'password2') }.to raise_error(PG::UniqueViolation)
    end
  end

  describe '#find_by_username' do
    it 'returns the user hash including password_hash when found' do
      repository.create('bob', 'password123')

      user = repository.find_by_username('bob')

      expect(user['username']).to eq('bob')
      expect(user['password_hash']).not_to be_nil
    end

    it 'returns nil when user does not exist' do
      user = repository.find_by_username('nonexistent')

      expect(user).to be_nil
    end
  end

end
