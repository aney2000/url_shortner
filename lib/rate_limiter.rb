# frozen_string_literal: true

class RateLimiter
  def initialize(max_requests:, window_seconds:)
    @max_requests = max_requests
    @window_seconds = window_seconds
    @requests = {}
  end

  def allow?(key)
    now = Time.now.to_f
    cleanup(key, now)

    timestamps = @requests[key] ||= []
    return false if timestamps.size >= @max_requests

    timestamps << now
    true
  end

  def reset!(key)
    @requests.delete(key)
  end

  private

  def cleanup(key, now)
    return unless @requests[key]

    cutoff = now - @window_seconds
    @requests[key].reject! { |ts| ts < cutoff }
    @requests.delete(key) if @requests[key].empty?
  end
end
