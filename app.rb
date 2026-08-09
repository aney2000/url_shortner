require 'sinatra/base'
require 'json'
require_relative 'lib/url_validator'
require_relative 'lib/short_code_generator'
require_relative 'lib/url_repository'

class UrlShortenerApp < Sinatra::Base
  # Initialize our in-memory repository once when the app boots up
  configure do
    set :repository, UrlRepository.new
  end

  # Endpoint 1: Create a short URL
  post '/shorten' do
    content_type :json
    
    # Safely parse the incoming JSON request body
    request_payload = JSON.parse(request.body.read) rescue {}
    long_url = request_payload['url']

    # 1. Validate the URL using our isolated validator
    unless UrlValidator.valid?(long_url)
      halt 400, { error: 'Invalid URL format' }.to_json
    end

    # 2. Generate a unique short code
    short_code = ShortCodeGenerator.generate
    
    # 3. Save the mapping in our repository
    settings.repository.save(short_code, long_url)

    # 4. Return the response back to the client
    base_url = request.base_url
    status 201
    { 
      short_code: short_code, 
      short_url: "#{base_url}/#{short_code}" 
    }.to_json
  end

  # Endpoint 2: Redirect to the original long URL
  get '/:short_code' do
    short_code = params[:short_code]
    
    # Find the original URL in our repository
    long_url = settings.repository.find_by_short_code(short_code)

    if long_url
      # If found, trigger an HTTP 301 redirect
      redirect long_url, 301
    else
      # If not found, return a 404 error
      halt 404, { error: 'URL not found' }.to_json
    end
  end
end
