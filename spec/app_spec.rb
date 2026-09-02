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
    conn = PG.connect(dbname: 'url_shortener_test')
    conn.exec('DELETE FROM users')
    conn.close
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

  describe 'POST / (web form)' do
    context 'when logged in' do
      before(:each) do
        post '/signup', username: 'alice', password: 'password123'
        post '/login', username: 'alice', password: 'password123'
      end

      it 'associates the shortened URL with the current user' do
        post '/', long_url: 'https://example.com'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include('Success!')
      end
    end

    context 'when not logged in' do
      it 'still shortens the URL anonymously' do
        post '/', long_url: 'https://example.com'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include('short link')
      end
    end
  end

  describe 'GET / (index)' do
    it 'shows login/signup links when not logged in' do
      get '/'

      expect(last_response.body).to include('Log In')
      expect(last_response.body).to include('Sign Up')
    end

    it 'shows username and logout when logged in' do
      post '/signup', username: 'alice', password: 'password123'
      post '/login', username: 'alice', password: 'password123'

      get '/'

      expect(last_response.body).to include('alice')
      expect(last_response.body).to include('Logout')
    end
  end
end
