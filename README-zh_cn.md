# rosso

一个（实验性质）的移动APP单点登录解决方案，用于企业内部的App之间使用统一用户账户做单点登录。

## rosso中的角色

rosso包含三种角色/子服务:

1. 通用票据存储（generic ticket storage，GTS）
2. TGT签发者（TGT issuer，TI）
3. ST签发者（ST issuer，SI）

## 名词解释

- TGT(ticket-granting ticket) 表示一个用户在rosso系统中的登录状态；App在获取TGT之后，可以通过它申请ST；
TGT样例```TGT-612e0548-cc7a-4813-aabc-bd8b410296d4```
- ST(service ticket) 表示一个用户对某个App的使用权限；
App从GTS中找到属于它（这台设备上的这个App）的ST，便可允许用户使用程序功能；
ST样例```ST-1-64346525-fe41-4908-acf6-6f4b56ac5e81```，`ST-1-`中的1表示该app在rosso中注册的id
- UDID(unique device ID) 区分一台移动设备的ID

## rosso使用简介

### 前提条件

- 客户App需要在rosso系统中注册（系统提供appkey和securekey）
- 需要确定设备唯一ID(UDID)的计算方法---详见文末说明

### API访问方式

- App们通过HTTP接口访问rosso的服务API
- 访问API需要附加特殊的HTTP header：

  1. X-APPKEY: App在rosso系统中注册后，系统发放的appkey值
  2. X-MAC: 对请求payload加上securekey进行散列（MD5 hexdigest）后的值；伪代码：
    ```
    MD5.hexdigest( "<payload>_<securekey>" )   // 中间用下划线连接
    // => '05c12a287334386c94131ab8aa00d08a'   // 返回样例
    ```

    其中，payload指的是：
    - 如果是POST请求，payload是HTTP body，也就是API请求的一些参数字面值
    - 其它请求，payload是请求的地址（path），如```http://service.host/api/user/john?param1=value1```中的```/api/user/john?param1=value1```部分

  3. X-UDID: 散列后的UDID，表示设备

### 注册用户流程

用户统一管理在rosso系统中，这里适应的场景是，App拥有自己的注册页面，通过调用rosso接口将用户关键数据传回rosso。

>App可以保留用户的额外信息在它的自己的库中。各个App的后台用户数据以在rosso中记录的登录名为主键。

```
获取用户信息：
GET /api/user/<username>
返回json：
{
   "user_id"    : <user.id>,
   "user_name"  : <user.name>,
   "user_type"  : <user.utype>,
   "created_at" : <user.created_at>,
   "access_to_this_app" : <true/false>
}

注册用户：
POST /api/user

username=newuser&password=123123
```

### 单点登录流程

##### 首次打开app1
1. app1使用UDID向GTS查询票据

```GET /api/store?udid=<udid>```
成功时返回状态码200，HTTP返回的body是GTS中保存的ticket值：
如果有ST，则是ST值；若没有ST但是有TGT，则是TGT；
如果都没有，返回403；
以及其它一些失败状态码和body数据：
```
400 "err: no param UDID"
... ...等等
```

2. 此时GTS中既没有app1的ST，也没有TGT，因此app1显示登录界面给用户（用户填写登录名、密码）
3. app1使用用户填写的登录名和密码访问TI，请求TGT：

```
POST /api/ticket

username=johndoe&password=123456
```

成功的返回：
```
201 CREATED
Location: /api/ticket/<TGT>
Content-Type: text/html

<TGT>
```

4. 如果成功，app1使用TGT向SI请求ST：
```
POST /api/ticket/<TGT>
```

成功返回：
```
200 OK

<ST>
```

5. 如果成功，表示用户已在rosso系统登录，可以使用app
（之后也可加上app1自己内部的用户登录逻辑，从而不必每次都向GTS查询ST来确定用户是否登录）

##### 首次打开app2
1. app2使用UDID向GTS查询票据
2. 虽然没有app2的ST，但是查询到TGT，表示该用户已经在rosso中登录
3. app2使用TGT向SI请求ST
4. 如果成功，表示用户可以访问app2


## UDID

UDID比较关键，业界也有许多不同的计算方法。每种方法各有千秋，也有不同的可靠性。
我们这里要求的可靠性较低，不需要该UDID在任何时间、任何情况下永久有效。
我们需要在可以接受的范围内确保该UDID可以区分设备就可以了。
因为通过该设备ID作为键存储的信息，最长不超过24小时，默认更短；
因此在这段时间，假定不发生换SIM卡，系统root、重装之类的变化。

>注意：
为不泄露用户隐私，不管UDID如何计算，在发送UDID时均发送其散列后的值。

### 安卓设备的UDID
推荐使用“伪ID（pseudo id）”的计算方法，它要求低、计算简单、可靠性尚可。请参考
[jared在StackOverflow上的回答](http://stackoverflow.com/a/17625641/6348731)

### iOS设备的UDID
因为iOS6之后，苹果不再允许使用原先的udid获取接口，“identifierForVendor”是目前比较推荐的方法。
尽管如此，它的局限性还是比较明显：

1. 如果是在App Store中发布的app，它们的vendor信息需要相同，即是同一家厂商发布的app
2. *或者*，app尚未发布，处于开发状态，它们的bundle ID需要符合一些条件才可以确保vendor ID相同。
请参考[苹果开发者站点](https://developer.apple.com/reference/uikit/uidevice/1620059-identifierforvendor)

[这个（中文）](http://iosapp.me/blog/2014/03/31/udid/)虽然是网上copy的内容，但是也是比较不伤眼的一篇总结。

