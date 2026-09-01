# frozen_string_literal: true

require_relative '../lib/postgres_repository'
require_relative 'support/shared_repository_contract'

RSpec.describe PostgresRepository do
  let(:repository) { PostgresRepository.new(dbname: 'url_shortener_test') }

  before(:each) do
    repository.clear!
  end

  after(:all) do
    repo = PostgresRepository.new(dbname: 'url_shortener_test')
    repo.clear!
    repo.close
  end

  it_behaves_like 'a url repository'

  describe 'PostgreSQL-specific behavior' do
    it 'enforces unique short codes' do
      repository.save('abc123', 'https://example.com')

      expect { repository.save('abc123', 'https://other.com') }.to raise_error(PG::UniqueViolation)
    end
  end
end
