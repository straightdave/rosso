# filters for public APIs (called by apps)
# mainly checking API accessibility: http headers and MAC
# provide @svc and @now to controller actions
# NOTE: @header_udid is the hashed udid
before '/api/*' do
  halt 400, "err: no header x-appkey" unless header_appkey = request.env["HTTP_X_APPKEY"]
  halt 400, "err: no header x-mac"    unless header_mac    = request.env["HTTP_X_MAC"]
  halt 400, "err: invalid service"    unless @svc = Service.find_by(appkey: header_appkey)

  # hashed UDID required at header
  halt 400, "err: no param UDID" unless @header_udid = request.env["HTTP_X_UDID"]

  # payload for MAC check
  if request.request_method == "POST"
    payload = request.body.read
    request.body.rewind
  else
    payload = request.path
  end
  halt 401, "err: wrong mac" unless header_mac == @svc.build_mac(payload)

  @now = Time.now
end
