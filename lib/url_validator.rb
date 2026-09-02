# frozen_string_literal: true

require 'uri'

class UrlValidator
  def self.valid?(url)
    return false if url.nil? || url.strip.empty?

    uri = URI.parse(url)
    (uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)) && !uri.host.nil? && !uri.host.empty?
  rescue URI::InvalidURIError
    false
  end
end
