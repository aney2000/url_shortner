# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require_relative 'lib/url_validator'
require_relative 'lib/short_code_generator'
require_relative 'lib/postgres_repository'
require_relative 'lib/user_repository'
require_relative 'lib/authenticator'

class UrlShortenerApp < Sinatra::Base
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET',
                                  'dev-secret-please-set-SESSION_SECRET-env-var-in-production-64chars-minimum!!')

  configure do
    db_conn = PG.connect(
      dbname: ENV.fetch('DATABASE_NAME', 'url_shortener_dev'),
      host: ENV.fetch('DATABASE_HOST', nil),
      port: ENV.fetch('DATABASE_PORT', 5432).to_i,
      user: ENV.fetch('DATABASE_USER', nil),
      password: ENV.fetch('DATABASE_PASSWORD', nil)
    )

    set :repository, PostgresRepository.new(
      dbname: ENV.fetch('DATABASE_NAME', 'url_shortener_dev'),
      host: ENV.fetch('DATABASE_HOST', nil),
      port: ENV.fetch('DATABASE_PORT', 5432).to_i,
      user: ENV.fetch('DATABASE_USER', nil),
      password: ENV.fetch('DATABASE_PASSWORD', nil)
    )

    user_repo = UserRepository.new(db_conn)
    set :authenticator, Authenticator.new(user_repo)
    set :user_repository, user_repo
  end

  helpers do
    def current_user
      return nil unless session[:user_id]

      settings.user_repository.find_by_id(session[:user_id])
    end

    def logged_in?
      !current_user.nil?
    end
  end

  # ==========================================
  # WEB UI ROUTES (For humans in a browser)
  # ==========================================

  get '/' do
    @current_user = current_user
    erb :index
  end

  post '/' do
    long_url = params[:long_url]
    @current_user = current_user

    if UrlValidator.valid?(long_url)
      short_code = ShortCodeGenerator.generate

      if @current_user
        settings.repository.save_with_user(short_code, long_url, @current_user['id'])
      else
        settings.repository.save(short_code, long_url)
      end

      @short_url = "#{request.base_url}/#{short_code}"
    else
      @error = 'Invalid URL format. Please include http:// or https://'
    end

    erb :index
  end

  # ==========================================
  # AUTH ROUTES
  # ==========================================

  get '/signup' do
    erb :signup
  end

  post '/signup' do
    username = params[:username]
    password = params[:password]

    if password.nil? || password.length < Authenticator::MIN_PASSWORD_LENGTH
      @error = 'Password must be at least 6 characters'
      return erb(:signup)
    end

    user = settings.authenticator.register(username, password)

    if user
      redirect '/login'
    else
      @error = 'Username already taken'
      erb :signup
    end
  end

  get '/login' do
    erb :login
  end

  post '/login' do
    user = settings.authenticator.login(params[:username], params[:password])

    if user
      session[:user_id] = user['id']
      redirect '/'
    else
      @error = 'Invalid username or password'
      erb :login
    end
  end

  post '/logout' do
    session.clear
    redirect '/'
  end

  # ==========================================
  # API ROUTES (For tests and external apps)
  # ==========================================

  post '/shorten' do
    content_type :json
    request_payload = begin
      JSON.parse(request.body.read)
    rescue StandardError
      {}
    end
    long_url = request_payload['url']

    halt 400, { error: 'Invalid URL format' }.to_json unless UrlValidator.valid?(long_url)

    short_code = ShortCodeGenerator.generate
    settings.repository.save(short_code, long_url)

    base_url = request.base_url
    status 201
    {
      short_code: short_code,
      short_url: "#{base_url}/#{short_code}"
    }.to_json
  end

  # ==========================================
  # REDIRECT ROUTE (Core Feature for both)
  # ==========================================

  get '/:short_code' do
    short_code = params[:short_code]
    long_url = settings.repository.find_by_short_code(short_code)

    if long_url
      redirect long_url, 301
    else
      halt 404, 'Sorry, this link does not exist.'
    end
  end
end
