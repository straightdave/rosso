require 'sinatra'
require 'sinatra/json'
require 'json'
require 'redis'
require 'active_record'
require 'securerandom'
require_relative 'controllers/_init'
require_relative 'models/_init'

set :public_folder, File.dirname(__FILE__) + '/public'
set :port, 8001
set :bind, '0.0.0.0'
set :tgt_expire, 5 * 60 * 60

log_file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
log_file.sync = true
use Rack::CommonLogger, log_file

ActiveRecord::Base.establish_connection(
  :adapter  => "mysql2",
  :host     => "localhost",
  :username => "dave",
  :password => "123123",
  :database => "rosso"
)
ActiveRecord::Base.default_timezone = :local

before do
  unless @redis = Redis.new(:host => "localhost", :port => 6379, :db => 5)
    halt 500, "err: redis is not ok"
  end
end

after do
  ActiveRecord::Base.connection.close
end

get '/' do
  'Ciao Rosso!'
end
