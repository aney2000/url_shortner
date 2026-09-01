# frozen_string_literal: true

ENV['APP_ENV'] = 'test'
ENV['DATABASE_NAME'] = 'url_shortener_test'

require_relative '../app'
require 'rack/test'

RSpec.describe 'UrlShortenerApp' do
  include Rack::Test::Methods

  def app
    UrlShortenerApp
  end

  before(:each) do
    app.settings.repository.clear!
  end

  describe 'POST /shorten' do
    it 'returns 400 Bad Request for an invalid URL' do
      post '/shorten', { url: 'not-a-valid-url' }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(400)
    end

    it 'returns 201 Created and the short URL for a valid payload' do
      post '/shorten', { url: 'https://rubylang.org' }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(201)

      response_body = JSON.parse(last_response.body)
      expect(response_body).to have_key('short_url')
      expect(response_body).to have_key('short_code')
    end
  end

  describe 'GET /:short_code' do
    it 'redirects to the long URL if the code exists' do
      post '/shorten', { url: 'https://github.com' }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      short_code = JSON.parse(last_response.body)['short_code']

      get "/#{short_code}"

      expect(last_response.status).to eq(301)
      expect(last_response.headers['location']).to eq('https://github.com')
    end

    it 'returns 404 Not Found if the code does not exist' do
      get '/unknown123'

      expect(last_response.status).to eq(404)
    end
  end
end
