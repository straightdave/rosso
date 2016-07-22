# request a TGT(Ticket-Granting Ticket) for user
# username and password are needed
# One user has only one TGT before it expires
# caller service can request a TGT for the user only if user has access to it
post '/api/tickets' do
  halt 400, "err: no username provided" unless name = params["username"]
  halt 400, "err: no password provided" unless password = params["password"]
  halt 404, "err: user does not exist"  unless user = User.find_by(name: name)
  halt 403, "err: wrong password"       unless user.authenticated?(password)

  if (stored_tgt = @redis.get "U-#{user.id}")
    tgt = stored_tgt
  else
    tgt = "TGT-#{SecureRandom.uuid}"

    # set same expiration (from settings) for all keys
    # and store the expire date in tgt_info
    #
    # store TGT as value and user.id as key
    # so that we can load TGT by user (as we do above)
    @redis.set "U-#{user.id}", tgt, { ex: settings.key_expire }

    # save some user info into tgt_info
    @redis.set tgt, {
      "user_id"    => user.id,
      "user_name"  => user.name,
      "created_at" => @now.to_i
    }.to_json, { ex: settings.key_expire }
  end

  # also, store this TGT into TGS
  @redis.sadd @header_udid, tgt
  @redis.expire @header_udid, settings.key_expire

  [201, {'Location' => "#{request.path}/#{tgt}", 'Content-Type' => 'text/html'}, [tgt]]
end

# GET ST: this API implements ST Issuer role
# request for an ST with TGT
# One user can get several STs(each per app) from rosso/other ST issuer
post '/api/tickets/:tgt' do |tgt|
  # no TGT means no such user logged in rosso
  halt 404, "err: TGT not exist"           unless @redis.exists(tgt)
  halt 500, "err: parsing TGT info failed" unless tgt_items = JSON.parse(@redis.get(tgt))
  halt 401, "err: invalid user_id"    unless user = User.find_by(id: tgt_items["user_id"])
  halt 403, "err: user has no access" unless user.has_access?(@svc)

  st_prefix = "ST-#{@svc.id}".freeze
  st_list = tgt_items["st_list"] || []

  if st_list.size > 0 &&
     (this_st = st_list.select {|x| x.start_with? st_prefix }) &&
     this_st.size > 0
    st = this_st.first
  else
    st = "#{st_prefix}-#{SecureRandom.uuid}"
    st_list << st
    @redis.set tgt, {
      "user_id"    => tgt_items["user_id"],
      "user_name"  => tgt_items["user_name"],
      "created_at" => tgt_items["created_at"],
      "st_list"    => st_list   # actually inserting an ST into tgt_info
    }.to_json, { ex: settings.key_expire }    # reset expiration

    # also, store this ST into TGS, expiring in 1 hour by default after the lastest ST added
    @redis.sadd @header_udid, st
    @redis.expire @header_udid, settings.key_expire
  end

  [200, [st]]
end

# API for single sign-out: delete stored TGT which represents user status
# 1. delete key 'U-{user.id}' (value: tgt)
# 2. delete key tgt (value: tgt_info)
# 3. delete key UDID (value: ST list)
delete '/api/tickets/:tgt' do |tgt|
  if tgt_info = @redis.get(tgt) && tgt_items = JSON.parse(tgt_info)
    @redis.del("U-#{tgt_items["user_id"]}")
  end
  @redis.del(tgt)
  @redis.del(@header_udid)

  [200, ["OK: TGT/ST cleaned"]]
end
