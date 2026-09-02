# frozen_string_literal: true

class RateLimiter
  SWEEP_INTERVAL = 300

  def initialize(max_requests:, window_seconds:)
    @max_requests = max_requests
    @window_seconds = window_seconds
    @requests = {}
    @mutex = Mutex.new
    @last_sweep = Time.now.to_f
  end

  def allow?(key)
    @mutex.synchronize do
      now = Time.now.to_f
      sweep(now)
      cleanup(key, now)

      timestamps = @requests[key] ||= []
      return false if timestamps.size >= @max_requests

      timestamps << now
      true
    end
  end

  def reset!(key)
    @mutex.synchronize do
      @requests.delete(key)
    end
  end

  private

  def cleanup(key, now)
    return unless @requests[key]

    cutoff = now - @window_seconds
    @requests[key].reject! { |ts| ts < cutoff }
    @requests.delete(key) if @requests[key].empty?
  end

  def sweep(now)
    return if now - @last_sweep < SWEEP_INTERVAL

    cutoff = now - @window_seconds
    @requests.each_key do |key|
      @requests[key].reject! { |ts| ts < cutoff }
    end
    @requests.reject! { |_, timestamps| timestamps.empty? }
    @last_sweep = now
  end
end
