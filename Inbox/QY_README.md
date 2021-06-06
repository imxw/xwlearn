# 基于蓝鲸SaaS开发框架，企业微信H5开发指南
## 预先准备
1. 注册企业微信账号并创建企业应用
    - 企业微信ID, 【“企业微信 → 我的企业 → 企业ID”】
    - 创建企业应用，并设置可见范围, 【“企业微信 → 应用与小程序 → 创建应用”】
    - 企业应用Secret, 【“企业微信 → 企业应用 → Secret”】
2. 申请应用外网域名
    - 建议同时申请https证书，后续需配置为https
3. 配置企业应用
    - 网页授权域名配置为应用外网域名【“企业微信 → 企业应用 → 网页授权及JS-SDK → 设置可信域名为应用外网应用域名”】
    - JS接口安全域名添加应用外网域名，完成域名归属验证【“企业微信 → 企业应用 → 网页授权及JS-SDK → 验证域名”】
## 创建蓝鲸应用
* 基本配置请参考 “蓝鲸智云开发者中心——》新手指南”
## 开发配置
### 获取 framework_weixin_package.tar.gz
> framework_weixin_package.tar.gz 解压
* 确保开发框架版本为1.1.0及以上
    - 将weixin目录复制于工程目录下
    - 将static/weixin的weixin目录复制到工程static目录下
    - 将templates/weixin的weixin目录复制到工程templates目录下
* 修改工程/weixin/core/settings.py配置
    - USE_WEIXIN 为True
    - IS_QY_WEIXIN 为True
    - WEIXIN_APP_ID 为企业CorpID
    - WEIXIN_APP_SECRET 为企业应用的Secret
    - WEIXIN_APP_EXTERNAL_HOST 为 申请的应用外网域名
### 修改工程配置文件
* 修改conf/default.py文件
```python
# 中间件 （MIDDLEWARE_CLASSES变量）添加
    # 添加到最前面
    'weixin.core.middlewares.WeixinProxyPatchMiddleware',
    # 正常追加到后面即可
    'weixin.core.middlewares.WeixinAuthenticationMiddleware',
    'weixin.core.middlewares.WeixinLoginMiddleware',
# INSTALLED_APPS 添加
    'weixin.core',
    'weixin',
# TEMPLATES （OPTIONS.context_processors）添加 'weixin.core.context_processors.basic'
    TEMPLATES = [
        {
            ...
            'OPTIONS': {
                'context_processors': [
                    # the context to the templates
                    'django.contrib.auth.context_processors.auth',
                    ...
                    # => 微信端可用的mako上下文变量
                    'weixin.core.context_processors.basic'
                ],
            },
        },
    ]

```
* 修改urls.py文件
```python
# urlpatterns 添加
    url(r'^weixin/login/', include('weixin.core.urls')),
    url(r'^weixin/', include('weixin.urls')),
```
## 蓝鲸应用
* 部署蓝鲸应用
## 运维配置
* 需要确保应用服务器能访问到微信API （可以只设置微信API的代理）
    - 微信提供的API 协议均为https
    - 域名为qyapi.weixin.qq.com
* 反向代理，将应用外网域名的部分路径指向内网蓝鲸应用
    - 为了保证安全，必须只反方向代理部分路径
    - 应用正式环境反向代理：/o/{bk_app_id}/weixin/和/o/{bk_app_id}/static/weixin/
    - 应用测试环境反向代理：/t/{bk_app_id}/weixin/和/t/{bk_app_id}/static/weixin/
    - header必需配置 X-Forwarded-Weixin-Host为应用外网域名，Host为蓝鲸内网域名
    - nginx反向代理示例：
```
server {
        listen              443;
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
        location ^~ /o/test_app/weixin/ {
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $http_host;
            proxy_set_header X-Forwarded-Weixin-Host $http_host;
            proxy_redirect off;
            proxy_read_timeout 180;
            proxy_pass http://paas.bking.com;
        }
        location ^~ /o/test_app/static/weixin/ {
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $http_host;
            proxy_set_header X-Forwarded-Weixin-Host $http_host;
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
* 直接手机微信访问  https://外网域名/o/{bk_app_id}/weixin/

## 基于企业微信的移动端开发说明
> 测试OK后，接下来的开发与PC端的开发基本一致

* 微信端CGI请求都得以 /o/{bk_app_id}/weixin/ （测试环境为：/o/{bk_app_id}/weixin/），若Mako模板渲染的页面，可直接使用${WEIXIN_SITE_URL}
* 微信端本地静态文件请求都得以 /o/{bk_app_id}/static/weixin/ （测试环境为：/o/{bk_app_id}/static/weixin/），若Mako模板渲染的页面，可直接使用${WEIXIN_STATIC_URL}
* 若对于不需要微信登录认证的请求，可直接在对应的View函数添加装饰器weixin_login_exempt（from weixin.core.decorators import weixin_login_exempt）
* 企业微信登录的用户都存储在BkWeixinUser模型（from weixin.core.models import BkWeixinUser）中，即数据库表 bk_weixin_user
* view函数中获取登录的用户方式：request.weixin_user 即为登录的用户的BkWeixinUser对象，具体weixin_user的属性等的可以查看weixin/core/models.py中的BkWeixinUser
