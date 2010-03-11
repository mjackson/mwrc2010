# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
require ::File.expand_path('../sinatra/app', __FILE__)

map '/' do
  run Mwrc::Application
end

map '/sinatra' do
  run SinatraApp.new
end
