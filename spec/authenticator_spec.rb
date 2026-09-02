# frozen_string_literal: true

require_relative '../lib/authenticator'
require_relative '../lib/user_repository'

RSpec.describe Authenticator do
  let(:pool) { test_db_pool }
  let(:user_repo) { UserRepository.new(pool) }
  let(:authenticator) { Authenticator.new(user_repo) }

  before(:each) do
    user_repo
    pool.with { |conn| conn.exec('DELETE FROM users') }
  end

  after(:all) do
    c = test_db_connection
    c.exec('DELETE FROM users') rescue nil # rubocop:disable Style/RescueModifier
    c.close
  end

  describe '#register' do
    it 'creates a new user and returns a success result' do
      result = authenticator.register('alice', 'password123')

      expect(result).to be_success
      expect(result.user['username']).to eq('alice')
    end

    it 'returns an error when username is already taken' do
      authenticator.register('alice', 'password123')

      result = authenticator.register('alice', 'otherpass123')

      expect(result).not_to be_success
      expect(result.error).to eq('Username already taken')
    end

    it 'returns an error when username is empty' do
      result = authenticator.register('', 'password123')

      expect(result).not_to be_success
      expect(result.error).to eq('Username is required')
    end

    it 'returns an error when username has invalid characters' do
      result = authenticator.register('al ice!@#', 'password123')

      expect(result).not_to be_success
      expect(result.error).to include('letters, numbers')
    end

    it 'returns an error when password is too short' do
      result = authenticator.register('alice', 'ab')

      expect(result).not_to be_success
      expect(result.error).to include('at least')
    end

    it 'returns an error when password exceeds 72 characters' do
      result = authenticator.register('alice', 'a' * 73)

      expect(result).not_to be_success
      expect(result.error).to include('at most')
    end
  end

  describe '#login' do
    before(:each) do
      authenticator.register('alice', 'correctpassword')
    end

    it 'returns the user hash when credentials are valid' do
      user = authenticator.login('alice', 'correctpassword')

      expect(user['username']).to eq('alice')
      expect(user['id']).not_to be_nil
    end

    it 'returns nil when password is wrong' do
      result = authenticator.login('alice', 'wrongpassword')

      expect(result).to be_nil
    end

    it 'returns nil when username does not exist' do
      result = authenticator.login('nonexistent', 'password')

      expect(result).to be_nil
    end
  end
end
