# rosso

one (exprimental) SSO solution written in ruby for generic mobile apps

## glossary

- TGT(ticket-granting ticket) which represents an user's sign-in status in rosso
- ST(service ticket) which represents the user's access to one app on a device
- UDID(unique device ID) which represents one mobile device in a proper time span


## roles in rosso

rosso consists of several sub-services which are:

1. generic ticket storage(GTS)
2. TGT issuer(TI)
3. ST issuer(SI)

## rosso usage overview

### prerequisites

- client apps should register in rosso (appkey and securekey given)
- every api call should have special HTTP headers
- unique device id(UDID) algorism should be provided

### sso process

##### app1 first open
1. user open app1
2. app1 calculates UDID and request for ST and TGT at GTS
3. neither ST nor TGT found, app1 prompts login page to user
4. with user's credential, app1 requests for a new TGT at TI
5. if done, then app1 requests for an ST with such TGT at SI
6. if ST issued, user can start to use app1 (app1 also does internally log-in)

##### app2 first open (same phone)
1. user open app2
2. app2 calculates UDID and request for ST and TGT at GTS
3. no ST for app2 but GTS has TGT for such UDID
4. with TGT app2 request for its ST at SI
5. if ST issued, user can start to use app2

## UDID

UDID is the unique ID for devices and there are several approaches to get UDID.
UDID should be same for apps on the same device (during a certain length period).
You can roll your own to calculate UDID.

### UDID for Android devices
'pseudo id' is recommended. please refer to
[jared's answer on StackOverflow](http://stackoverflow.com/a/17625641/6348731)

### UDID for iOS devices
'identifierForVendor' is recommended for now.
but it is tricky since Apple's policy for the uniqueness crossing apps.

1. apps should be published in AppStore by same vendor
2. OR, if apps are in local development, bundle ID should be same in first two parts:
`com.vendor.app1` and `com.vendor.app2`.
(please refer to [apple developer site](https://developer.apple.com/reference/uikit/uidevice/1620059-identifierforvendor))

for Chinese developers, [here](http://iosapp.me/blog/2014/03/31/udid/) is a good article.
