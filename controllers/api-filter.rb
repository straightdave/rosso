# filters for public APIs (called by apps)
#
# NOTE:
# currently rosso is used by mobile apps
# so UDID is required (must see it in header)
#
# for UDID
# IOS(>=6): use identifierForVendor (like 599F9C00-92DC-4B5C-9464-7971F01F8370)
# ANDROID: use pseudo id (snippet: http://stackoverflow.com/questions/2785485/is-there-a-unique-android-device-id), jared's answer
#          it looks like a hashed IMEI string
before '/api/*' do
  halt 400, "err: no header x-appkey" unless header_appkey = request.env["HTTP_X_APPKEY"]
  halt 400, "err: no header x-mac"    unless header_mac    = request.env["HTTP_X_MAC"]
  halt 400, "err: no header x-udid"   unless @header_udid  = request.env["HTTP_X_UDID"]
  # NOTE: to validate the udid. here's just a simple approach: checking length
  #       could use other more complex and precise approaches
  halt 400, "err: invalid UDID"       unless @header_udid.size > 5
  halt 400, "err: invalid service"    unless @svc = Service.find_by(appkey: header_appkey)

  # payload for MAC check
  if request.request_method == "POST"
    payload = request.body
    request.body.rewind
  else
    payload = request.path
  end
  halt 401, "err: wrong mac" unless header_mac == @svc.build_mac(payload)

  @now = Time.now
end
