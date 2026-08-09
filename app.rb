require 'sinatra/base'
require 'json'
require_relative 'lib/url_validator'
require_relative 'lib/short_code_generator'
require_relative 'lib/sqlite_repository'

class UrlShortenerApp < Sinatra::Base
  configure do
    # Initialize the SQLite database connection once
    set :repository, SqliteRepository.new('production.db')
  end

  # ==========================================
  # WEB UI ROUTES (For humans in a browser)
  # ==========================================
  
  get '/' do
    erb :index
  end

  post '/' do
    long_url = params[:long_url]

    if UrlValidator.valid?(long_url)
      short_code = ShortCodeGenerator.generate
      settings.repository.save(short_code, long_url)
      @short_url = "#{request.base_url}/#{short_code}"
    else
      @error = "Invalid URL format. Please include http:// or https://"
    end
    
    erb :index
  end

  # ==========================================
  # API ROUTES (For tests and external apps)
  # ==========================================

  post '/shorten' do
    content_type :json
    request_payload = JSON.parse(request.body.read) rescue {}
    long_url = request_payload['url']

    unless UrlValidator.valid?(long_url)
      halt 400, { error: 'Invalid URL format' }.to_json
    end

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
      halt 404, "Sorry, this link does not exist."
    end
  end
end
