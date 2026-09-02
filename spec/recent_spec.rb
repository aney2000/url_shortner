# frozen_string_literal: true

ENV['APP_ENV'] = 'test'
ENV['DATABASE_NAME'] = 'url_shortener_test'

require_relative '../app'
require 'rack/test'

RSpec.describe 'Recent links' do
  include Rack::Test::Methods

  def app
    UrlShortenerApp
  end

  before(:each) do
    app.settings.repository.clear!
    conn = PG.connect(dbname: 'url_shortener_test')
    conn.exec('DELETE FROM users')
    conn.close
  end

  describe 'GET /recent' do
    it 'renders the recent links page' do
      get '/recent'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Recent Links')
    end

    it 'shows recently shortened links' do
      post '/shorten', { url: 'https://example.com' }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      post '/shorten', { url: 'https://github.com' }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      get '/recent'

      expect(last_response.body).to include('https://example.com')
      expect(last_response.body).to include('https://github.com')
    end

    it 'shows a message when no links exist' do
      get '/recent'

      expect(last_response.body).to include('No links shortened yet')
    end
  end
end
