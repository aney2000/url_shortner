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

      # Using a Regular Expression to ensure it only has a-z, A-Z, or 0-9
      expect(code).to match(/^[a-zA-Z0-9]+$/)
    end

    it 'generates random unique codes (highly probable)' do
      code1 = ShortCodeGenerator.generate
      code2 = ShortCodeGenerator.generate

      expect(code1).not_to eq(code2)
    end

    it 'allows generating codes of custom length' do
      code = ShortCodeGenerator.generate(8)

      expect(code.length).to eq(8)
    end
  end
end
