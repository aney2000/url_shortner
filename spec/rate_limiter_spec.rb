# frozen_string_literal: true

require_relative '../lib/rate_limiter'

RSpec.describe RateLimiter do
  subject(:limiter) { RateLimiter.new(max_requests: 3, window_seconds: 60) }

  describe '#allow?' do
    it 'allows requests under the limit' do
      expect(limiter.allow?('user1')).to be true
      expect(limiter.allow?('user1')).to be true
      expect(limiter.allow?('user1')).to be true
    end

    it 'blocks requests over the limit' do
      3.times { limiter.allow?('user1') }

      expect(limiter.allow?('user1')).to be false
    end

    it 'tracks different keys independently' do
      3.times { limiter.allow?('user1') }

      expect(limiter.allow?('user2')).to be true
    end

    it 'resets after the window expires' do
      limiter = RateLimiter.new(max_requests: 1, window_seconds: 0.1)
      limiter.allow?('user1')

      expect(limiter.allow?('user1')).to be false

      sleep(0.15)

      expect(limiter.allow?('user1')).to be true
    end
  end

  describe '#reset!' do
    it 'clears the counter for a key' do
      3.times { limiter.allow?('user1') }
      expect(limiter.allow?('user1')).to be false

      limiter.reset!('user1')

      expect(limiter.allow?('user1')).to be true
    end
  end
end
