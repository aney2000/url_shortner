# frozen_string_literal: true

require 'bcrypt'

class Authenticator
  MIN_PASSWORD_LENGTH = 6

  def initialize(user_repository)
    @user_repository = user_repository
  end

  def register(username, password)
    return nil if username.nil? || username.strip.empty?
    return nil if password.nil? || password.length < MIN_PASSWORD_LENGTH

    @user_repository.create(username, password)
  rescue PG::UniqueViolation
    nil
  end

  def login(username, password)
    user = @user_repository.find_by_username(username)
    return nil unless user

    stored_hash = BCrypt::Password.new(user['password_hash'])
    return nil unless stored_hash == password

    { 'id' => user['id'], 'username' => user['username'] }
  end
end
