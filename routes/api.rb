# frozen_string_literal: true

module Routes
  module Api
    def self.registered(app)
      app.post '/shorten' do
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
    end
  end
end
