# check user name exists / get user info by name
# will return some basic info to the caller service
# mainly used when registering users
get '/api/user/:name' do |name|
  halt 464, "err: user does not exist" unless user = User.find_by(name: name)
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

# create an universal user account for SSO
# used by service side sign-up
post '/api/user' do
  halt 460, "err: no username"     unless name = params["username"]
  halt 460, "err: no password"     unless password = params["password"]
  halt 460, "err: no email"        unless email = params["email"]
  halt 460, "err: no phone-number" unless phone = params["phone"]
  halt 466, "err: name in use"     if User.exists(name: name)
  halt 466, "err: email in use"    if User.exists(email: email)
  halt 466, "err: phone in use"    if User.exists(phone: phone)

  if user = User.create_user(name, password, email, phone)
    ['201', ["USER ID=#{user.id} CREATED"]]
  else
    ['500', ["USER CREATION FAILED"]]
  end
end
