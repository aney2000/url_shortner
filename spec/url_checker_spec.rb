# frozen_string_literal: true

require_relative '../lib/url_checker'

RSpec.describe UrlChecker do
  describe '.check' do
    it 'returns reachable for a live public URL' do
      result = UrlChecker.check('https://www.google.com')

      expect(result).to be_reachable
      expect(result.warning).to be_nil
    end

    it 'returns unreachable with warning for a non-existent host' do
      result = UrlChecker.check('https://this-host-does-not-exist-xyz123abc.com')

      expect(result).not_to be_reachable
      expect(result.warning).not_to be_nil
    end

    it 'blocks private/internal addresses (SSRF protection)' do
      result = UrlChecker.check('http://127.0.0.1/admin')

      expect(result).not_to be_reachable
      expect(result.warning).to include('private')
    end

    it 'blocks localhost (SSRF protection)' do
      result = UrlChecker.check('http://localhost:5432')

      expect(result).not_to be_reachable
      expect(result.warning).to include('private')
    end

    it 'blocks 169.254.x.x metadata addresses (SSRF protection)' do
      result = UrlChecker.check('http://169.254.169.254/latest/meta-data/')

      expect(result).not_to be_reachable
      expect(result.warning).to include('private')
    end
  end

  describe '.safe_host?' do
    it 'returns true for public hosts' do
      expect(UrlChecker.safe_host?('google.com')).to be true
    end

    it 'returns false for localhost' do
      expect(UrlChecker.safe_host?('localhost')).to be false
    end

    it 'returns false for private IPs' do
      expect(UrlChecker.safe_host?('192.168.1.1')).to be false
      expect(UrlChecker.safe_host?('10.0.0.1')).to be false
      expect(UrlChecker.safe_host?('172.16.0.1')).to be false
    end
  end
end
