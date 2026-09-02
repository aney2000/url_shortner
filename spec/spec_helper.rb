# frozen_string_literal: true

ENV['APP_ENV'] = 'test'
ENV['DATABASE_NAME'] ||= 'url_shortener_test'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
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
