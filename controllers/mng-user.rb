get '/mng/user/:name/services' do |name|
  halt 464, "err: invalid user name" unless user = User.find_by(name: name)

  # TODO

end
