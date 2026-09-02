# frozen_string_literal: true

require_relative '../lib/short_code_generator'

RSpec.describe ShortCodeGenerator do
  describe '.generate' do
    it 'generates a string of the default length (6 characters)' do
      code = ShortCodeGenerator.generate

      expect(code.length).to eq(6)
    end

    it 'contains only Base62 characters (alphanumeric)' do
      code = ShortCodeGenerator.generate

      expect(code).to match(/^[a-zA-Z0-9]+$/)
    end

    it 'generates different codes on consecutive calls' do
      code1 = ShortCodeGenerator.generate
      code2 = ShortCodeGenerator.generate

      expect(code1).not_to eq(code2)
    end

    it 'allows generating codes of custom length' do
      code = ShortCodeGenerator.generate(8)

      expect(code.length).to eq(8)
    end
  end

  describe '.generate_unique' do
    let(:repository) { double('repository') }

    it 'returns the first code when no collision' do
      allow(repository).to receive(:find_by_short_code).and_return(nil)

      code = ShortCodeGenerator.generate_unique(repository)

      expect(code.length).to eq(6)
    end

    it 'retries on collision and returns a unique code' do
      call_count = 0
      allow(repository).to receive(:find_by_short_code) do
        call_count += 1
        call_count < 3 ? 'https://existing.com' : nil
      end

      code = ShortCodeGenerator.generate_unique(repository)

      expect(code.length).to eq(6)
      expect(call_count).to eq(3)
    end

    it 'raises after MAX_RETRIES collisions' do
      allow(repository).to receive(:find_by_short_code).and_return('https://existing.com')

      expect { ShortCodeGenerator.generate_unique(repository) }.to raise_error(/Failed to generate/)
    end
  end
end
