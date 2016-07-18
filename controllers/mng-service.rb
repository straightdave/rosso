post '/api/service' do
  halt 460, "err: no valid name"           unless name = params["name"]
  halt 460, "err: no valid type"           unless type = params["type"]
  halt 465, "err: service name duplicated" unless Service.exists?(name: name)

  if service = Service.create_service(name, type)
    ['201', ["SERVICE ID=#{service.id} CREATED"]]
  else
    ['500', ["SERVICE CREATION FAILED"]]
  end
end

post '/api/service/:name/refreshkey' do |name|
  halt 464, "err: invalid service name" unless service = Service.find_by(name: name)
  if service.refresh_keys!
    ['201', ['KEYS REFRESHED']]
  else
    ['500', ['KEY REFRESHING FAILED']]
  end
end

get '/api/service/:name' do |name|
  halt 464, "err: invalid service name" unless service = Service.find_by(name: name)
  json {
    "service_id"   => service.id,
    "service_name" => service.name,
    "service_type" => service.type,
    "created_at"   => service.created_at
  }
end

get '/api/services' do
  type = case params['type']
  when 'inner' then 'inner'
  when 'vendor' then 'vendor'
  when 'mng' then 'mng'
  else 'custom'
  end

  limit = params['limit'] || 50
  offset = params['offset'] || 0
  results = Service.where(type: type).limit(limit).offset(offset)

  ret = []
  results.each do |svc|
    ret << {
      "service_id" => svc.id,
      "service_name" => svc.name,
      "service_type" => svc.type,
      "created_at" => svc.created_at
    }
  end
  json ret
end
