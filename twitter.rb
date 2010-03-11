require 'open-uri'
require 'rack'
require 'rack-mobile-detect'
require 'json'
require 'plist'

class TwitterCacheApp

  # The number of seconds to keep something in cache. Twitter API limit is 150/hour.
  CACHE_SECONDS = (60 / (150.0 / 60)).freeze

  @cache = {}

  class << self
    attr_reader :cache
  end

  def cache
    self.class.cache
  end

  def call(env)
    dup._call(env)
  end

  def _call(env)
    @res = Rack::Response.new
    req = Rack::Request.new(env)
    user = req.params['user']
    body = blank?(user) ? {} : data(user)
    if wants_plist?(env)
      plist(body)
    else
      json(body)
    end
    @res.finish
  rescue
    error $!
    @res.finish
  end

private

  def blank?(obj)
    obj.nil? || obj.empty?
  end

  def uri(user, format='json')
    'http://api.twitter.com/l/statuses/user_timeline/%s.%s' % [user, format]
  end

  def data(user)
    update_cache(user) if cache_needs_updating?(user)
    cache[user][:data]
  end

  def update_cache(user)
    data = open(uri(user, 'json')) {|f| f.read }
    cache[user] = { :time => Time.now, :data => JSON.parse(data) }
  end

  def cache_needs_updating?(user)
    !cache.has_key?(user) || cache[user][:time] < (Time.now - CACHE_SECONDS)
  end

  def wants_plist?(env)
    env['X_MOBILE_DEVICE'] == 'iPhone' || env['X_MOBILE_DEVICE'] == 'iPod'
  end

  def plist(obj)
    @res['Content-Type'] = 'application/plist+xml'
    @res.write obj.to_plist
  end

  def json(obj, headers={})
    @res['Content-Type'] = 'application/json'
    @res.write obj.to_json
  end

  def error(bang)
    @res.status = 500
    @res['Content-Type'] = 'text/plain'
    @res.write bang.message
  end

end

HELP = <<MSG
This is a demonstration of a self-contained Rack app, including tests. It
serves as a rudimentary cache for Twitter status requests that will prevent
the client from exceeding the Twitter API request/hour limit. To
run it, make sure you have the rack, rack-test, rack-mobile-detect, json,
and plist gems installed, then do one of these:

  ruby twitter.rb           # start the server
  ruby twitter.rb --test    # run the tests
  ruby twitter.rb --help    # view this message

Once the server is running, hit up the server with a request like this:

  curl -X GET http://localhost:9292/?user=mjijackson

If you send a HTTP User-Agent header that identifies an iPhone or iPod, the
result will be returned as a plist. Otherwise, you'll get the result as JSON.
It should go without saying that you need to be connected to a network in
order to query the Twitter servers. In other words, don't try and run this
in a live presentation at a Ruby conference that is crowded with people who
are hammering the network. :]
MSG

if $0 == __FILE__
  case ARGV[0]
  when '--help', '-h'
    puts HELP
  when '--test'
    require 'test/unit'
    require 'rack/test'

    class TwitterCacheAppTester < Test::Unit::TestCase
      include Rack::Test::Methods

      def app
        TwitterCacheApp.new
      end

      # Sample UA strings. First is iPhone, second is iPod.
      # Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_1 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7C144 Safari/528.16
      # Mozilla/5.0 (iPod; U; CPU iPhone OS 2_2 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5G77 Safari/525.20

      def test_response_format_json
        get '/'
        assert last_response.ok?
        assert_equal 'application/json', last_response['Content-Type']
      end

      # fails, don't know why
      def test_response_format_plist_for_iphone
        header 'User-Agent', 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_1 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7C144 Safari/528.16'
        get '/'
        assert last_response.ok?
        assert_equal 'application/plist+xml', last_response['Content-Type']
      end

      # fails, don't know why
      def test_response_format_plist_for_ipod
        header 'User-Agent', 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_1 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7C144 Safari/528.16'
        response = get '/'
        assert response.ok?
        assert_equal 'application/plist+xml', response['Content-Type']
      end
    end
  else
    app = Rack::Builder.new {
      use Rack::MobileDetect
      run TwitterCacheApp.new
    }.to_app
    Rack::Handler::WEBrick.run app, :Port => 9292
  end
end
