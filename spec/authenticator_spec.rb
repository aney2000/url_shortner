# frozen_string_literal: true

require_relative '../lib/authenticator'
require_relative '../lib/user_repository'

RSpec.describe Authenticator do
  let(:conn) { PG.connect(dbname: 'url_shortener_test') }
  let(:user_repo) { UserRepository.new(conn) }
  let(:authenticator) { Authenticator.new(user_repo) }

  before(:each) do
    user_repo
    conn.exec('DELETE FROM users')
  end

  after(:all) do
    c = PG.connect(dbname: 'url_shortener_test')
    c.exec('DELETE FROM users') rescue nil # rubocop:disable Style/RescueModifier
    c.close
  end

  describe '#register' do
    it 'creates a new user and returns the user hash' do
      user = authenticator.register('alice', 'password123')

      expect(user['id']).not_to be_nil
      expect(user['username']).to eq('alice')
    end

    it 'returns nil when username is already taken' do
      authenticator.register('alice', 'password123')

      result = authenticator.register('alice', 'otherpass')

      expect(result).to be_nil
    end

    it 'returns nil when username is empty' do
      result = authenticator.register('', 'password123')

      expect(result).to be_nil
    end

    it 'returns nil when password is too short' do
      result = authenticator.register('alice', 'ab')

      expect(result).to be_nil
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
