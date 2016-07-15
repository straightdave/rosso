# check user name exists / get user info by name
# will return some basic info to the caller service
# mainly used when registering users
get '/api/user/:name' do |name|
  halt 464, "err: user does not exist" unless user = User.find_by(name: name)
  ['200',
    [
      {
        "user_id"    => user.id,
        "user_name"  => user.name,
        "user_type"  => user.type,
        "created_at" => user.created_at,
        "access_to_this_app" => user.has_access?(@svc)
      }.to_json
    ]
  ]
end

# create an universal user
post '/api/user' do


end
