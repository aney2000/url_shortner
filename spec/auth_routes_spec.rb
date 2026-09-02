# frozen_string_literal: true

require_relative '../app'
require 'rack/test'

RSpec.describe 'Authentication routes' do
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

  describe 'GET /signup' do
    it 'renders the signup form' do
      get '/signup'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Sign Up')
    end
  end

  describe 'POST /signup' do
    it 'creates a user and redirects to login on success' do
      post '/signup', username: 'alice', password: 'password123'

      expect(last_response.status).to eq(302)
      expect(last_response.headers['location']).to include('/login')
    end

    it 'shows error for duplicate username' do
      post '/signup', username: 'alice', password: 'password123'
      post '/signup', username: 'alice', password: 'otherpass123'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Username already taken')
    end

    it 'shows error for short password' do
      post '/signup', username: 'alice', password: 'ab'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Password must be at least 6 characters')
    end

    it 'shows error for empty username' do
      post '/signup', username: '', password: 'password123'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Username already taken')
    end
  end

  describe 'GET /login' do
    it 'renders the login form' do
      get '/login'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Log In')
    end
  end

  describe 'POST /login' do
    before(:each) do
      post '/signup', username: 'alice', password: 'password123'
    end

    it 'logs in and redirects to home on valid credentials' do
      post '/login', username: 'alice', password: 'password123'

      expect(last_response.status).to eq(302)
      expect(last_response.headers['location']).to include('/')
    end

    it 'shows error on invalid credentials' do
      post '/login', username: 'alice', password: 'wrongpass'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Invalid username or password')
    end
  end

  describe 'POST /logout' do
    it 'clears session and redirects to login' do
      post '/signup', username: 'alice', password: 'password123'
      post '/login', username: 'alice', password: 'password123'
      post '/logout'

      expect(last_response.status).to eq(302)
      expect(last_response.headers['location']).to include('/login')
    end

    it 'prevents access to / after logout' do
      post '/signup', username: 'alice', password: 'password123'
      post '/login', username: 'alice', password: 'password123'
      post '/logout'

      get '/'

      expect(last_response.status).to eq(302)
      expect(last_response.headers['location']).to include('/login')
    end
  end
end
