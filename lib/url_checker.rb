# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'resolv'
require 'ipaddr'

class UrlChecker
  TIMEOUT = 4
  PRIVATE_RANGES = [
    IPAddr.new('10.0.0.0/8'),
    IPAddr.new('172.16.0.0/12'),
    IPAddr.new('192.168.0.0/16'),
    IPAddr.new('127.0.0.0/8'),
    IPAddr.new('169.254.0.0/16'),
    IPAddr.new('0.0.0.0/8'),
    IPAddr.new('::1/128'),
    IPAddr.new('fc00::/7')
  ].freeze

  CheckResult = Struct.new(:reachable, :warning, keyword_init: true) do
    def reachable? = reachable
  end

  def self.check(url)
    uri = URI.parse(url)
    return ssrf_warning unless safe_host?(uri.host)

    evaluate_response(head_request(uri))
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH,
         Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    unreachable(network_error_message(e))
  rescue StandardError
    unreachable('Could not verify URL')
  end

  def self.network_error_message(error)
    case error
    when SocketError then 'Could not resolve host'
    when Net::OpenTimeout, Net::ReadTimeout then 'Request timed out'
    else 'Host is unreachable'
    end
  end
  private_class_method :network_error_message

  def self.evaluate_response(response)
    if response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
      CheckResult.new(reachable: true, warning: nil)
    else
      unreachable("URL returned HTTP #{response.code}")
    end
  end
  private_class_method :evaluate_response

  def self.unreachable(warning)
    CheckResult.new(reachable: false, warning: warning)
  end
  private_class_method :unreachable

  def self.safe_host?(host)
    ips = Resolv.getaddresses(host)
    ips.none? { |ip| private_ip?(ip) }
  rescue Resolv::ResolvError
    false
  end

  def self.private_ip?(ip_string)
    addr = IPAddr.new(ip_string)
    PRIVATE_RANGES.any? { |range| range.include?(addr) }
  rescue IPAddr::InvalidAddressError
    true
  end
  private_class_method :private_ip?

  def self.head_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT
    http.request(Net::HTTP::Head.new(uri.request_uri))
  end
  private_class_method :head_request

  def self.ssrf_warning
    CheckResult.new(reachable: false, warning: 'URL points to a private/internal address')
  end
  private_class_method :ssrf_warning
end
