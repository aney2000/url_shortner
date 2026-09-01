# frozen_string_literal: true

require_relative '../lib/sqlite_repository'
require_relative 'support/shared_repository_contract'

RSpec.describe SqliteRepository do
  let(:repository) { SqliteRepository.new(':memory:') }

  it_behaves_like 'a url repository'
end
