# frozen_string_literal: true

require_relative '../lib/url_checker'

RSpec.describe UrlChecker do
  describe '.check' do
    context 'when host is reachable' do
      it 'returns reachable for a successful response' do
        allow(Resolv).to receive(:getaddresses).with('example.com').and_return(['93.184.216.34'])
        response = instance_double(Net::HTTPOK, code: '200')
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(false)
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_return(response)

        result = UrlChecker.check('https://example.com')

        expect(result).to be_reachable
        expect(result.warning).to be_nil
      end

      it 'returns reachable for a redirect response' do
        allow(Resolv).to receive(:getaddresses).with('example.com').and_return(['93.184.216.34'])
        response = instance_double(Net::HTTPRedirection, code: '301')
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(true)
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_return(response)

        result = UrlChecker.check('https://example.com')

        expect(result).to be_reachable
      end
    end

    context 'when host returns an error' do
      it 'returns unreachable with HTTP status warning' do
        allow(Resolv).to receive(:getaddresses).with('example.com').and_return(['93.184.216.34'])
        response = instance_double(Net::HTTPNotFound, code: '404')
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(false)
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_return(response)

        result = UrlChecker.check('https://example.com')

        expect(result).not_to be_reachable
        expect(result.warning).to eq('URL returned HTTP 404')
      end
    end

    context 'when host is unreachable' do
      it 'returns unreachable on connection refused' do
        allow(Resolv).to receive(:getaddresses).with('down.example.com').and_return(['93.184.216.34'])
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_raise(Errno::ECONNREFUSED)

        result = UrlChecker.check('https://down.example.com')

        expect(result).not_to be_reachable
        expect(result.warning).to eq('Host is unreachable')
      end

      it 'returns unreachable on timeout' do
        allow(Resolv).to receive(:getaddresses).with('slow.example.com').and_return(['93.184.216.34'])
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_raise(Net::OpenTimeout)

        result = UrlChecker.check('https://slow.example.com')

        expect(result).not_to be_reachable
        expect(result.warning).to eq('Request timed out')
      end

      it 'returns unreachable on DNS failure' do
        allow(Resolv).to receive(:getaddresses).with('nonexistent.example.com').and_return(['93.184.216.34'])
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_raise(SocketError.new('getaddrinfo: Name or service not known'))

        result = UrlChecker.check('https://nonexistent.example.com')

        expect(result).not_to be_reachable
        expect(result.warning).to eq('Could not resolve host')
      end
    end

    context 'SSRF protection' do
      it 'blocks private addresses' do
        allow(Resolv).to receive(:getaddresses).with('127.0.0.1').and_return(['127.0.0.1'])

        result = UrlChecker.check('http://127.0.0.1/admin')

        expect(result).not_to be_reachable
        expect(result.warning).to include('private')
      end

      it 'blocks localhost' do
        allow(Resolv).to receive(:getaddresses).with('localhost').and_return(['127.0.0.1'])

        result = UrlChecker.check('http://localhost:5432')

        expect(result).not_to be_reachable
        expect(result.warning).to include('private')
      end

      it 'blocks cloud metadata addresses' do
        allow(Resolv).to receive(:getaddresses).with('169.254.169.254').and_return(['169.254.169.254'])

        result = UrlChecker.check('http://169.254.169.254/latest/meta-data/')

        expect(result).not_to be_reachable
        expect(result.warning).to include('private')
      end
    end
  end
end
