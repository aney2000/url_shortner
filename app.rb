# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'connection_pool'
require_relative 'lib/url_validator'
require_relative 'lib/url_checker'
require_relative 'lib/short_code_generator'
require_relative 'lib/postgres_repository'
require_relative 'lib/user_repository'
require_relative 'lib/authenticator'
require_relative 'lib/rate_limiter'
require_relative 'routes/auth'
require_relative 'routes/api'

class UrlShortenerApp < Sinatra::Base
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') {
    if ENV['APP_ENV'] == 'production' || ENV['RACK_ENV'] == 'production'
      raise 'SESSION_SECRET environment variable is required in production'
    end

    'dev-secret-do-not-use-in-production-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
  }
  set :protection, except: :json_csrf

  configure do
    db_pool = ConnectionPool.new(size: Integer(ENV.fetch('DB_POOL_SIZE', 5)), timeout: 5) do
      PG.connect(
        dbname: ENV.fetch('DATABASE_NAME', 'url_shortener_dev'),
        host: ENV.fetch('DATABASE_HOST', nil),
        port: ENV.fetch('DATABASE_PORT', 5432).to_i,
        user: ENV.fetch('DATABASE_USER', nil),
        password: ENV.fetch('DATABASE_PASSWORD', nil)
      )
    end

    # UserRepository first -- urls table FK references users
    user_repo = UserRepository.new(db_pool)
    set :authenticator, Authenticator.new(user_repo)
    set :user_repository, user_repo

    set :repository, PostgresRepository.new(db_pool)
    set :shorten_limiter, RateLimiter.new(max_requests: 20, window_seconds: 60)
    set :login_limiter, RateLimiter.new(max_requests: 5, window_seconds: 60)
  end

  helpers do
    def h(text)
      Rack::Utils.escape_html(text.to_s)
    end

    def current_user
      return nil unless session[:user_id]

      { 'id' => session[:user_id], 'username' => session[:username] }
    end

    def require_login
      @current_user = current_user
      redirect '/login' unless @current_user
    end

    def client_ip
      request.ip
    end
  end

  register Routes::Auth
  register Routes::Api

  # ==========================================
  # WEB UI ROUTES
  # ==========================================

  get '/' do
    require_login
    @links = settings.repository.find_by_user(@current_user['id'])
    @base_url = request.base_url
    erb :index
  end

  post '/' do
    require_login
    long_url = params[:long_url]

    unless settings.shorten_limiter.allow?(client_ip)
      @error = 'Too many requests. Please wait a moment.'
      @links = settings.repository.find_by_user(@current_user['id'])
      @base_url = request.base_url
      return erb(:index)
    end

    unless UrlValidator.valid?(long_url)
      @error = 'Invalid URL format. Please include http:// or https://'
      @links = settings.repository.find_by_user(@current_user['id'])
      @base_url = request.base_url
      return erb(:index)
    end

    check = UrlChecker.check(long_url)
    @url_warning = check.warning unless check.reachable?

    short_code = ShortCodeGenerator.generate_unique(settings.repository)
    settings.repository.save_with_user(short_code, long_url, @current_user['id'])
    @short_url = "#{request.base_url}/#{short_code}"

    @links = settings.repository.find_by_user(@current_user['id'])
    @base_url = request.base_url
    erb :index
  end

  get '/dashboard' do
    require_login
    @links = settings.repository.find_by_user(@current_user['id'])
    @base_url = request.base_url
    erb :dashboard
  end

  get '/recent' do
    @current_user = current_user
    @links = settings.repository.recent(20)
    @base_url = request.base_url
    erb :recent
  end

  # ==========================================
  # REDIRECT ROUTE (must be last - catch-all)
  # ==========================================

  get '/:short_code' do
    short_code = params[:short_code]
    long_url = settings.repository.find_by_short_code(short_code)

    if long_url
      redirect long_url, 302
    else
      halt 404, erb(:not_found)
    end
  end
end
