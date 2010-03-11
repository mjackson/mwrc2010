require 'sinatra/base'

class SinatraApp < Sinatra::Base

  get '/' do
    'Hello from Sinatra!'
  end

end
