# frozen_string_literal: true

module Routes
  module Auth
    def self.registered(app)
      app.get '/signup' do
        erb :signup
      end

      app.post '/signup' do
        username = params[:username]
        password = params[:password]

        if password.nil? || password.length < Authenticator::MIN_PASSWORD_LENGTH
          @error = 'Password must be at least 6 characters'
          return erb(:signup)
        end

        user = settings.authenticator.register(username, password)

        if user
          redirect '/login'
        else
          @error = 'Username already taken'
          erb :signup
        end
      end

      app.get '/login' do
        erb :login
      end

      app.post '/login' do
        user = settings.authenticator.login(params[:username], params[:password])

        if user
          session[:user_id] = user['id']
          redirect '/'
        else
          @error = 'Invalid username or password'
          erb :login
        end
      end

      app.post '/logout' do
        session.clear
        redirect '/login'
      end
    end
  end
end
