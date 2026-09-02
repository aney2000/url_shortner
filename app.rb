# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require_relative 'lib/url_validator'
require_relative 'lib/short_code_generator'
require_relative 'lib/postgres_repository'
require_relative 'lib/user_repository'
require_relative 'lib/authenticator'
require_relative 'routes/auth'
require_relative 'routes/api'

class UrlShortenerApp < Sinatra::Base
  enable :sessions
  set :session_secret,
      ENV.fetch('SESSION_SECRET', 'dev-secret-please-set-SESSION_SECRET-env-var-in-production-64chars-minimum!!')

  configure do
    db_conn = PG.connect(
      dbname: ENV.fetch('DATABASE_NAME', 'url_shortener_dev'),
      host: ENV.fetch('DATABASE_HOST', nil),
      port: ENV.fetch('DATABASE_PORT', 5432).to_i,
      user: ENV.fetch('DATABASE_USER', nil),
      password: ENV.fetch('DATABASE_PASSWORD', nil)
    )

    set :repository, PostgresRepository.new(db_conn)

    user_repo = UserRepository.new(db_conn)
    set :authenticator, Authenticator.new(user_repo)
    set :user_repository, user_repo
  end

  helpers do
    def current_user
      return nil unless session[:user_id]

      settings.user_repository.find_by_id(session[:user_id])
    end

    def require_login
      @current_user = current_user
      redirect '/login' unless @current_user
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

    if UrlValidator.valid?(long_url)
      short_code = ShortCodeGenerator.generate_unique(settings.repository)
      settings.repository.save_with_user(short_code, long_url, @current_user['id'])
      @short_url = "#{request.base_url}/#{short_code}"
    else
      @error = 'Invalid URL format. Please include http:// or https://'
    end

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
      redirect long_url, 301
    else
      halt 404, erb(:not_found)
    end
  end
end
