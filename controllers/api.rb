# filters for APIs
before '/api/*' do
  # check appkey and MAC to validate calling from clients
  halt 460, "err: no header x-appkey" unless header_appkey = request.env["HTTP_X_APPKEY"]
  halt 460, "err: no header x-mac"    unless header_mac = request.env["HTTP_X_MAC"]
  halt 460, "err: invalid appkey"     unless client = Client.find_by(appkey: header_appkey)
  halt 461, "err: wrong mac"          unless header_mac == client.build_mac(request.path)
end

# check user name exists / get user info by name
get '/api/user/:name' do |name|
  halt 464, "err: user does not exist" unless user = User.find_by(name: name)
  json ret: "OK", data: {
    "user_id"    => user.id,
    "user_name"  => user.name,
    "user_type"  => user.type,
    "created_at" => user.created_at
  }
end

# create a TGT(Ticket-Granting Ticket)
# username and password needed
post '/api/tickets' do
  halt 460, "err: no valid username"   unless name = params["username"]
  halt 460, "err: no valid password"   unless password = params["password"]
  halt 464, "err: user does not exist" unless user = User.find_by(name: name)
  halt 461, "err: wrong password"      unless user.authenticated?(password)

  tgt = "TGT-#{SecureRandom.uuid}"
  now = Time.now
  @redis.set tgt, {
    "user_name"      => user.name,
    "tgt_created_at" => now.to_i,
    "tgt_expired_at" => (now + 5 * 60 * 60).to_i
  }.to_json

  location = "#{request.path}/#{tgt}"
  body_lines = []
  body_lines << "<!DOCTYPE HTML><html><head><title>201 CREATED</title></head><body>"
  body_lines << "<h1>TGT Created</h1><form action='#{location}' method='POST'>"
  body_lines << "Service:<input type='text' name='service' value=''>"
  body_lines << "<br><input type='submit' value='Submit'></form></body></html>"

  ['201', {'Location' => location, 'Content-Type' => 'text/html'}, body_lines]
end

# request an ST
post '/api/tickets/:tgt' do |tgt|
  now = Time.now
  halt 460, "err: TGT does not exist"    unless tgt_info = @redis.get(tgt)
  halt 460, "err: invalid TGT info"      unless tgt_items = JSON.parse(tgt_info)
  halt 461, "err: TGT expired"           unless now.to_i < tgt_items["tgt_expired_at"]
  halt 460, "err: no client id provided" unless client_id = params["client"]
  halt 461, "err: invalid client"        unless client = Client.find_by(id: client_id)
  halt 461, "err: invalid user"  unless user = User.find_by(name: tgt_items["user_name"])

  st = "ST-#{SecureRandom.uuid}"
  @redis.set tgt, {
    "user_name"      => tgt_items["user_name"],
    "tgt_created_at" => tgt_items["tgt_created_at"],
    "tgt_expired_at" => tgt_items["tgt_expired_at"],
    "st"             => st
  }.to_json

  ['200', [st]]
end

# logout
delete '/api/tickets/:tgt' do |tgt|
  @redis.del(tgt)

  ['200', ['TGT Deleted']]
end

