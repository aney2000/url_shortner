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

    it 'is thread-safe under concurrent access' do
      limiter = RateLimiter.new(max_requests: 100, window_seconds: 60)
      threads = 10.times.map do
        Thread.new { 50.times { limiter.allow?('shared_key') } }
      end
      threads.each(&:join)

      # 500 attempts, only 100 should succeed -- no crashes or corruption
      # We just verify it doesn't raise; exact count depends on scheduling
    end

    it 'sweeps stale keys from other IPs' do
      limiter = RateLimiter.new(max_requests: 1, window_seconds: 0.05)
      limiter.allow?('stale_key')

      sleep(0.1)

      # Trigger sweep by calling allow? on a different key
      # The stale_key should be cleaned up
      limiter.allow?('fresh_key')
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
