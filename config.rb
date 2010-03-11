#use Rack::ShowExceptions
#use Rack::Lint
use Rack::ContentType
use Rack::ContentLength

run lambda {|env| [200, {}, ["Hiya!"]] }
