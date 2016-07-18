# request a TGT(Ticket-Granting Ticket) for user
# username and password are needed
# One user has only one TGT before it expires
# caller service can request a TGT for the user only if user has access to it
post '/api/tickets' do
  halt 460, "err: no valid username"   unless name = params["username"]
  halt 460, "err: no valid password"   unless password = params["password"]
  halt 464, "err: user does not exist" unless user = User.find_by(name: name)
  halt 463, "err: wrong password"      unless user.authenticated?(password)
  halt 462, "err: user has no access"  unless user.has_access?(@svc)

  if (stored_tgt = @redis.get "U-#{user.id}")   &&
     (tgt_info   = @redis.get stored_tgt)       &&
     (tgt_items  = JSON.parse(tgt_info) )       &&
     (@now.to_i  < tgt_items["tgt_expired_at"])
    tgt = stored_tgt
  else
    tgt = "TGT-#{SecureRandom.uuid}"
    @redis.set "U-#{user.id}", tgt
    @redis.set tgt, {
      "user_id"        => user.id,
      "user_name"      => user.name,
      "tgt_created_at" => @now.to_i,
      "tgt_expired_at" => (@now + settings.tgt_expire).to_i
    }.to_json
  end

  ['201', {'Location' => "#{request.path}/#{tgt}", 'Content-Type' => 'text/html'}, [tgt]]
end

# request an ST
# One user has several STs of apps from CAS
post '/api/tickets/:tgt' do |tgt|
  halt 460, "err: TGT does not exist" unless tgt_info = @redis.get(tgt)
  halt 460, "err: invalid TGT info"   unless tgt_items = JSON.parse(tgt_info)
  halt 461, "err: TGT expired"        unless @now.to_i < tgt_items["tgt_expired_at"]
  halt 461, "err: invalid user"       unless user = User.find_by(id: tgt_items["user_id"])
  halt 462, "err: user has no access" unless user.has_access?(@svc)

  st_prefix = "ST-#{@svc.id}"
  st_list = tgt_items["st_list"] || []

  if st_list.size > 0 && (this_st = st_list.select! {|x| x.start_with?(st_prefix) })
    st = this_st.first
  else
    st = "#{st_prefix}-#{SecureRandom.uuid}"
    st_list << st
    @redis.set tgt, {
      "user_id"        => tgt_items["user_id"],
      "user_name"      => tgt_items["user_name"],
      "tgt_created_at" => tgt_items["tgt_created_at"],
      "tgt_expired_at" => tgt_items["tgt_expired_at"],
      "st_list"        => st_list
    }.to_json
  end

  ['200', [st]]
end

# service to call this will make a single sign-out
delete '/api/tickets/:tgt' do |tgt|
  if tgt_info = @redis.get(tgt) && tgt_items = JSON.parse(tgt_info)
    @redis.del("U-#{tgt_items["user_id"]}")
  end
  @redis.del(tgt)

  ['200', ['TGT Deleted']]
end
