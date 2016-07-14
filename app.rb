require 'sinatra'
require 'sinatra/json'
require 'json'
require 'redis'
require 'active_record'
require 'securerandom'
require 'sinatra/cookies'
require_relative 'controllers/_init'
require_relative 'models/_init'

set :public_folder, File.dirname(__FILE__) + '/public'
set :port, 8001
set :bind, '0.0.0.0'

ActiveRecord::Base.establish_connection(
  :adapter  => "mysql2",
  :host     => "localhost",
  :username => "dave",
  :password => "123123",
  :database => "russo"
)
ActiveRecord::Base.default_timezone = :local

before do
  unless @redis = Redis.new(:host => "localhost", :port => 6379, :db => 5)
    halt 560, "err: redis is not ok"
  end
end

after do
  ActiveRecord::Base.connection.close
end

get '/' do
  'ciao russo!'
end
