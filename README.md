# rosso

one (exprimental) SSO solution written in ruby for generic mobile apps

## glossary

- TGT(ticket-granting ticket) which represents an user's sign-in status in rosso
- ST(service ticket) which represents the user's access to one client service(a.k.a. app)
- UDID(unique device ID) which represents one mobile device in a proper time span


## roles in rosso

rosso consists of several sub-services which are:
1. generic tickets storage(GTS)
2. TGT issuer(TI)
3. ST issuer(SI)

## rosso usage overview

### prerequisites

- client apps should register in rosso (appkey and securekey given)
- every api call should have special HTTP headers
- unique device id(UDID) algorism should be provided

### sso process

##### first open app1
1. user open app1
2. app1 calculates UDID and request TGT and its ST from GTS

request:
```
GET /api/store

X-APPKEY: (app's id key)
X-MAC: (hashed request payload)
X-UDID: (device's udid)
```

3. no TGT (as well as ST) found, app1 shows a login page to user
4. with user input credential, app1 request for a new TGT
4. if done then app1 requests for an ST from ST Issuer with such TGT
5. if done, with ST for app1, user can use app1 (app1 logs in such user)

##### first open app2 (same phone)
1. user open app2
2. app2 calculates UDID and request for TGT from GTS
3. TGT is found in GTS (so no login page prompted)
4. with TGT app2 queries its ST
5. if ST not found, app2 request for its ST with TGT
6. if done, with ST for app2, user can user app2 (app2 logs in such user)
