# frozen_string_literal: true

ENV['APP_ENV'] = 'test'
ENV['RACK_ENV'] = 'test'
ENV['DATABASE_NAME'] ||= 'url_shortener_test'

require 'connection_pool'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Reset rate limiters between integration tests to prevent cross-spec leakage
  config.before(:each) do
    if defined?(UrlShortenerApp) && UrlShortenerApp.respond_to?(:settings)
      UrlShortenerApp.settings.shorten_limiter.reset!('127.0.0.1')
      UrlShortenerApp.settings.login_limiter.reset!('127.0.0.1')
    end
  end
end

def test_db_pool
  @test_db_pool ||= ConnectionPool.new(size: 2, timeout: 5) do
    PG.connect(
      dbname: ENV.fetch('DATABASE_NAME', 'url_shortener_test'),
      host: ENV.fetch('DATABASE_HOST', nil),
      port: ENV.fetch('DATABASE_PORT', 5432).to_i,
      user: ENV.fetch('DATABASE_USER', nil),
      password: ENV.fetch('DATABASE_PASSWORD', nil)
    )
  end
end

def test_db_connection
  PG.connect(
    dbname: ENV.fetch('DATABASE_NAME', 'url_shortener_test'),
    host: ENV.fetch('DATABASE_HOST', nil),
    port: ENV.fetch('DATABASE_PORT', 5432).to_i,
    user: ENV.fetch('DATABASE_USER', nil),
    password: ENV.fetch('DATABASE_PASSWORD', nil)
  )
end
