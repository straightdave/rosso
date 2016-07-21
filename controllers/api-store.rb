# generic tickets storage(GTS)
#
# this role provides a solution (interfaces + redis storage)
# for devices to store udid-tgt key-value pairs
# instead of storing them at local device storage
# which is difficult to share among clients natively
#
# this API checks ST from TGS by providing params(mainly the unique device id)
# to see whether calling user has signed in rosso via this device
# and whether he/she has access to such app
#
# params:
# - udid(unique device identity) is required and is provided in header 'x-udid'
# return:
# - 200 and the ST which means that user has access to this app now
# - 403
#
# for UDID
# IOS(>=6): use identifierForVendor (like 599F9C00-92DC-4B5C-9464-7971F01F8370)
# ANDROID: use pseudo id (snippet: http://stackoverflow.com/questions/2785485/is-there-a-unique-android-device-id), jared's answer
#          it looks like a hashed IMEI string
get '/api/store' do
  # in TGS, udid is the key, the value is a ST list
  st_prefix = "ST-#{@svc.id}".freeze
  if (st_list = @redis.smembers udid) &&
     (st_list.size > 0) &&
     (my_st = st_list.find {|st| st.start_with? st_prefix })
    ['200', [my_st]]
  else
    halt 403, "Unauthenticated: No ST for this device, user to such app"
  end
end
