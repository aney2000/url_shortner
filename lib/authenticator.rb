# frozen_string_literal: true

require 'bcrypt'

class Authenticator
  MIN_PASSWORD_LENGTH = 6
  MAX_PASSWORD_LENGTH = 72
  USERNAME_FORMAT = /\A[a-zA-Z0-9_-]{1,50}\z/

  RegisterResult = Struct.new(:user, :error, keyword_init: true) do
    def success? = !user.nil?
  end

  def initialize(user_repository)
    @user_repository = user_repository
  end

  def register(username, password)
    error = validate_registration(username, password)
    return RegisterResult.new(error: error) if error

    user = @user_repository.create(username.strip, password)
    RegisterResult.new(user: user)
  rescue PG::UniqueViolation
    RegisterResult.new(error: 'Username already taken')
  end

  def login(username, password)
    user = @user_repository.find_by_username(username)
    return nil unless user

    stored_hash = BCrypt::Password.new(user['password_hash'])
    return nil unless stored_hash == password

    { 'id' => user['id'], 'username' => user['username'] }
  end

  private

  def validate_registration(username, password)
    validate_username(username) || validate_password(password)
  end

  def validate_username(username)
    return 'Username is required' if username.nil? || username.strip.empty?

    return if username.strip.match?(USERNAME_FORMAT)

    'Username must be 1-50 characters: letters, numbers, hyphens, underscores'
  end

  def validate_password(password)
    return 'Password is required' if password.nil? || password.empty?
    return "Password must be at least #{MIN_PASSWORD_LENGTH} characters" if password.length < MIN_PASSWORD_LENGTH
    return "Password must be at most #{MAX_PASSWORD_LENGTH} characters" if password.length > MAX_PASSWORD_LENGTH

    nil
  end
end
