# frozen_string_literal: true

RSpec.shared_examples 'a url repository' do
  describe '#save and #find_by_short_code' do
    it 'stores a url and retrieves it by short code' do
      repository.save('aB3x9', 'https://www.rubylang.org')

      result = repository.find_by_short_code('aB3x9')

      expect(result).to eq('https://www.rubylang.org')
    end

    it 'returns nil when the short code does not exist' do
      result = repository.find_by_short_code('unknown')

      expect(result).to be_nil
    end

    it 'handles multiple urls independently' do
      repository.save('code1', 'https://example.com')
      repository.save('code2', 'https://other.com')

      expect(repository.find_by_short_code('code1')).to eq('https://example.com')
      expect(repository.find_by_short_code('code2')).to eq('https://other.com')
    end
  end
end
