# frozen_string_literal: true

module Routes
  module Api
    def self.registered(app)
      app.post '/shorten' do
        content_type :json

        halt 429, { error: 'Too many requests' }.to_json unless settings.shorten_limiter.allow?(client_ip)

        begin
          request_payload = JSON.parse(request.body.read)
        rescue JSON::ParserError
          halt 400, { error: 'Invalid JSON' }.to_json
        end

        long_url = request_payload['url']
        halt 400, { error: 'Invalid URL format' }.to_json unless UrlValidator.valid?(long_url)

        check = UrlChecker.check(long_url)
        warning = check.warning unless check.reachable?

        short_code = create_short_url(settings.repository, long_url)

        status 201
        response_body = {
          short_code: short_code,
          short_url: "#{request.base_url}/#{short_code}"
        }
        response_body[:warning] = warning if warning

        response_body.to_json
      end
    end
  end
end
