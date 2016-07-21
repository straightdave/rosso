# check user name exists / get user info by name
# will return some basic info to the caller service
# mainly used when registering users
get '/api/user/:name' do |name|
  halt 404, "err: user not found" unless user = User.find_by(name: name)
  ['200',
    [{
       "user_id"    => user.id,
       "user_name"  => user.name,
       "user_type"  => user.type,
       "created_at" => user.created_at,
       "access_to_this_app" => user.has_access?(@svc)
    }.to_json]
  ]
end

# create a custom-type user ('cause called by public apps') in rosso
# called in app-side sign-up process
#
# params:
# - username (distinct)
# - password
# - email (distinct)
# - phone number (distinct)
# return:
# - new user's id
# - errors otherwise
#
# NOTE: for now (2016/07/22) only username is required and should be distinct
#
post '/api/user' do
  halt 400, "err: no username"     unless name = params["username"]
  halt 400, "err: no password"     unless password = params["password"]
  # halt 400, "err: no email"        unless email = params["email"]
  # halt 400, "err: no phone-number" unless phone = params["phone"]
  halt 406, "err: name in use"     if User.exists(name: name)
  # halt 406, "err: email in use"    if User.exists(email: email)
  # halt 406, "err: phone in use"    if User.exists(phone: phone)

  if user = User.create_user(name, password)
    ['201', [user.id]]
  else
    ['500', ["USER CREATION FAILED"]]
  end
end

# another single sign-out API
# (because no public caller is able to delete user from rosso
# to delete one user, use 'delete /mng/user/:name')
#
# 1. delete key 'U-{user.id}' (value: tgt)
# 2. delete key tgt (value: tgt_info)
# 3. delete key UDID (value: ST list)
delete '/api/user/:name' do |name|
  # TODO
end
