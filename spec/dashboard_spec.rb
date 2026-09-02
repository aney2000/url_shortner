# frozen_string_literal: true

ENV['APP_ENV'] = 'test'
ENV['DATABASE_NAME'] = 'url_shortener_test'

require_relative '../app'
require 'rack/test'

RSpec.describe 'Dashboard' do
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

  describe 'GET /dashboard' do
    context 'when not logged in' do
      it 'redirects to login' do
        get '/dashboard'

        expect(last_response.status).to eq(302)
        expect(last_response.headers['location']).to include('/login')
      end
    end

    context 'when logged in' do
      before(:each) do
        post '/signup', username: 'alice', password: 'password123'
        post '/login', username: 'alice', password: 'password123'
      end

      it 'shows the dashboard page' do
        get '/dashboard'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include('My Links')
      end

      it 'shows no links message when user has none' do
        get '/dashboard'

        expect(last_response.body).to include('No links yet')
      end

      it 'displays links the user has shortened' do
        post '/', long_url: 'https://example.com'
        post '/', long_url: 'https://github.com'

        get '/dashboard'

        expect(last_response.body).to include('https://example.com')
        expect(last_response.body).to include('https://github.com')
      end

      it 'does not show links from other users' do
        post '/', long_url: 'https://alice-link.com'
        post '/logout'

        post '/signup', username: 'bob', password: 'password123'
        post '/login', username: 'bob', password: 'password123'

        get '/dashboard'

        expect(last_response.body).not_to include('https://alice-link.com')
      end
    end
  end
end
