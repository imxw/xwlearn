# 基于蓝鲸SaaS开发框架，微信小程序开发指南
## 预先准备
1. 申请微信小程序号
    - 小程序AppID/AppSecret, 【“微信小程序 → 设置 → 开发配置 → 开发者ID”】
    - 测试可先申请小程序测试号：https://developers.weixin.qq.com/sandbox
2. 申请应用外网域名
    - 同时申请https证书，后续需配置为https，微信小程序只接受后端服务有ssl的请求
3. 配置小程序
    - request合法域名配置为应用外网域名【“微信小程序 → 设置 → 开发配置 → 服务器域名”】
    - 其他合法域名根据需要设置为应用外网域名
## 创建蓝鲸应用
* 基本配置请参考 “蓝鲸智云开发者中心——》新手指南”
## 开发配置
### 获取 framework_miniweixin_package.tar.gz
> framework_miniweixin_package.tar.gz 解压
* 确保开发框架版本为1.1.0及以上
    - 将miniweixin目录复制于工程目录下
    - 将templates/miniweixin的miniweixin目录复制到工程templates目录下
    - 本地开发需要安装python包pycrypto
* 修改工程/miniweixin/core/settings.py配置
    - USE_MINIWEIXIN 为True
    - MINIWEIXIN_APP_ID 为申请的微信小程序的AppID
    - MINIWEIXIN_APP_SECRET 为申请微信小程序的AppSecret
    - MINIWEIXIN_APP_EXTERNAL_HOST 为 申请的应用外网域名
* 修改工程/templates/miniweixin/project.config.json配置
    - appid 为申请的微信小程序的AppID
    - projectname为小程序项目名称
    - 工程/template/miniweixin的miniweixin目录即为微信小程序前端代码，可使用微信开发者工具打开
* 修改/templates/miniweixin/config.js配置
    - 设置APP_URL_PREFIX为应用外网域名和路径前缀URL，如：https://paas.external.bking.com/\<o|t\>/\<bk_app_id\>/miniweixin/

### 修改工程配置文件
* 修改conf/default.py文件
```python
# 中间件 （MIDDLEWARE_CLASSES变量）添加
    # 添加到最前面
    'miniweixin.core.middlewares.MiniWeixinProxyPatchMiddleware',
    ...
    # 正常后面追加即可
    'miniweixin.core.middlewares.MiniWeixinCsrfExemptMiddleware',
    'miniweixin.core.middlewares.MiniWeixinRequestBodyJsonMiddleware',
    'miniweixin.core.middlewares.MiniWeixinAuthenticationMiddleware',
    'miniweixin.core.middlewares.MiniWeixinLoginMiddleware',
# INSTALLED_APPS 添加
    'miniweixin.core',
    'miniweixin',
```
* 修改urls.py文件
```python
# urlpatterns 添加
    url(r'^miniweixin/login/', include('miniweixin.core.urls')),
    url(r'^miniweixin/', include('miniweixin.urls')),
```
## 蓝鲸应用
* 部署蓝鲸应用
## 运维配置
* 需要确保应用服务器能访问到微信API （可以只设置微信API的代理）
    - 微信提供的API 协议均为https
    - 域名为api.weixin.qq.com
* 反向代理，将应用外网域名的部分路径指向内网蓝鲸应用
    - 为了保证安全，必须只反方向代理部分路径
    - 应用正式环境反向代理：/o/{bk_app_id}/miniweixin/
    - 应用测试环境反向代理：/t/{bk_app_id}/miniweixin/
    - header必需配置X-Forwarded-Miniweixin-Host为应用外网域名，Host为蓝鲸内网域名
    - nginx反向代理示例：
```
server {
        listen              443; # https还得配置证书，证书配置请看nginx官方文档
        server_name        paas.external.bking.com; # 填写应用外网域名

       # https相关配置
        ssl                 on;
        ssl_certificate     demo.crt; # 配置对应crt
        ssl_certificate_key demo.key; # 配置对应key
        ssl_session_timeout  10m;
        ssl_session_cache shared:SSL:1m;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2; #按照这个协议配置
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;#按照这个套件配置
        ssl_prefer_server_ciphers on;

        # 假设bk_app_id = test_app，且配置应用的正式环境
        location ^~ /o/test_app/miniweixin/ {
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $http_host;
            proxy_set_header X-Forwarded-Miniweixin-Host $http_host;
            proxy_redirect off;
            proxy_read_timeout 180;
            proxy_pass http://paas.bking.com;
        }
        # 其他不做任何代理，直接返回404即可
        location / {
            return 404;
        }
}
```
## 测试是否OK
* 在微信开发者工具中，在对应工程的界面上找到预览按钮，点击预览
* 直接手机微信扫描预览二维码访问

## 小程序体验版本发布和正式版本发布
* 请直接小程序官方文档
    - 发布前准备 https://developers.weixin.qq.com/miniprogram/dev/quickstart/basic/role.html
    - 上传小程序 https://developers.weixin.qq.com/miniprogram/dev/quickstart/basic/release.html
    - 小程序信息完善及开发前准备 https://developers.weixin.qq.com/miniprogram/introduction/#%E5%B0%8F%E7%A8%8B%E5%BA%8F%E4%BF%A1%E6%81%AF%E5%AE%8C%E5%96%84%E5%8F%8A%E5%BC%80%E5%8F%91%E5%89%8D%E5%87%86%E5%A4%87
    - 代码审核与发布 https://developers.weixin.qq.com/miniprogram/introduction/#%E4%BB%A3%E7%A0%81%E5%AE%A1%E6%A0%B8%E4%B8%8E%E5%8F%91%E5%B8%83

## 基于微信小程序的移动端开发说明
> 测试OK后，接下来的开发，主要是使用蓝鲸应用开发小程序后端接口，同时也集成了前端开发登录相关代码，其他前端开发请直接参考小程序官方文档

### 蓝鲸SaaS小程序后端开发说明
* 小程序CGI请求都得以 /o/{bk_app_id}/miniweixin/ （测试环境为：/o/{bk_app_id}/miniweixin/）
* 若对于不需要微信小程序登录认证的请求，可直接在对应的View函数添加装饰器miniweixin_login_exempt（from miniweixin.core.decorators import miniweixin_login_exempt）
* 微信小程序登录的用户都存储在BkMiniWeixinUser模型（from miniweixin.core.models import BkMiniWeixinUser）中，即数据库表 bk_mini_weixin_user
* 集成的微信小程序登录默认是静默登录，只能获取用户openid，其他信息需要设置为授权登录，可配置参考前端的授权更新用户信息模块
* view函数中获取登录的用户方式：request.miniweixin_user 即为登录的用户的BkMiniWeixinUser对象，具体miniweixin_user的属性等的可以查看miniweixin/core/models.py中的BkMiniWeixinUser
### 蓝鲸SaaS小程序前端登录相关开发说明
* 请阅读工程/templates/miniweixin/readme.md
* 更多小程序前端样例，请访问https://magicbox.bk.tencent.com/#wx_build/show
### 微信小程序官方开发文档
https://developers.weixin.qq.com/miniprogram/dev/index.html?t=201879
