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
# - 200, the ST for current App; if no ST, it may return the TGT for current user
# - 403 if no ST or TGT; or other errors
get '/api/store' do
  halt 403, "Unauthenticated: no UDID key"  unless (ticket_list = @redis.smembers @header_udid)
  halt 403, "Unauthenticated: no tickets stored" unless ticket_list.size > 0

  tgt_prefix = "TGT".freeze
  st_prefix  = "ST-#{@svc.id}".freeze
  my_st = ticket_list.select {|t| (t.start_with? st_prefix) }
  my_tgt = ticket_list.select {|t| (t.start_with? st_prefix) }

  if my_st.size > 0
    [200, [my_st.first]]
  elsif my_tgt.size > 0
    [200, [my_tgt.first]]
  else
    halt 403, "Unauthenticated: no ST or TGT"
  end
end
