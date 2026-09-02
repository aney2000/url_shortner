# frozen_string_literal: true

require_relative '../app'
require 'rack/test'

RSpec.describe 'UrlShortenerApp' do
  include Rack::Test::Methods

  def app
    UrlShortenerApp
  end

  before(:each) do
    app.settings.repository.clear!
    conn = test_db_connection
    conn.exec('DELETE FROM users')
    conn.close
  end

  def sign_up_and_login(username = 'alice', password = 'password123')
    post '/signup', username: username, password: password
    post '/login', username: username, password: password
  end

  describe 'GET / (access control)' do
    it 'redirects to /login when not logged in' do
      get '/'

      expect(last_response.status).to eq(302)
      expect(last_response.headers['location']).to include('/login')
    end

    it 'shows the shortener when logged in' do
      sign_up_and_login

      get '/'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Shorten')
    end
  end

  describe 'POST / (web form)' do
    it 'redirects to /login when not logged in' do
      post '/', long_url: 'https://example.com'

      expect(last_response.status).to eq(302)
      expect(last_response.headers['location']).to include('/login')
    end

    it 'shortens a valid URL when logged in' do
      sign_up_and_login

      post '/', long_url: 'https://example.com'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Success!')
    end

    it 'shows error for invalid URL when logged in' do
      sign_up_and_login

      post '/', long_url: 'not-a-url'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Invalid URL format')
    end
  end

  describe 'POST /shorten (API)' do
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

    it 'returns 404 for unknown short code' do
      get '/unknown123'

      expect(last_response.status).to eq(404)
    end
  end

  describe 'GET / (index with history)' do
    it 'shows the user link history on the main page' do
      sign_up_and_login

      post '/', long_url: 'https://example.com'
      post '/', long_url: 'https://github.com'

      get '/'

      expect(last_response.body).to include('https://example.com')
      expect(last_response.body).to include('https://github.com')
    end

    it 'shows no history message when user has no links' do
      sign_up_and_login

      get '/'

      expect(last_response.body).to include('No links yet')
    end
  end

  describe 'GET /recent' do
    it 'is accessible without login' do
      get '/recent'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Recent Links')
    end
  end
end
