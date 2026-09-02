# frozen_string_literal: true

module Routes
  module Auth
    def self.registered(app)
      app.get '/signup' do
        erb :signup
      end

      app.post '/signup' do
        result = settings.authenticator.register(params[:username], params[:password])

        if result.success?
          redirect '/login'
        else
          @error = result.error
          erb :signup
        end
      end

      app.get '/login' do
        erb :login
      end

      app.post '/login' do
        unless settings.login_limiter.allow?(client_ip)
          @error = 'Too many login attempts. Please wait a moment.'
          return erb(:login)
        end

        user = settings.authenticator.login(params[:username], params[:password])

        if user
          session[:user_id] = user['id']
          session[:username] = user['username']
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
