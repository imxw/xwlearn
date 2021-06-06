### 蓝鲸微信小程序模版

#### 目录结构

- `app.js`：小程序主入口，这里包含了获取用户信息、蓝鲸统一登录；
- `app.wxss`：小程序全局样式；
- `app.json`：对当前小程序的全局配置，包括了小程序的所有页面路径、界面表现、网络超时时间、底部 tab 等；
- `config.js`：接口配置，可配置您企业内部搭建的蓝鲸企业版SaaS小程序登录入口；
- `pages`：小程序每个视图单独一个目录，包括结构`wxml`、样式`wxss`、表现`js`三大块代码；
- `assets`：资源目录，包含蓝鲸提供的小程序样式文件`bkui.wxss`;
- `utils`：公共函数模块目录；
- `components`：公共组件目录；
- `auth`：蓝鲸登录授权模块；
- `images`：存放图片；

#### 使用蓝鲸登录授权模块（如果您的小程序后台服务基于蓝鲸企业版SaaS开发，可启用该模块）
- 引入`auth` 和 `auth-modal`模块，其中`auth/auth.js`包含了登录和授权相关方法，`auth-modal`则是需要使用微信授权时统一弹窗；
- 引入后在`app.js`的`onLaunch`里执行this.initBkAuth()进行初始化；
- 发起异步请求时，可以调用蓝鲸封装异步请求函数`app.requestWithCredentials`，方法时已经统一加入bktoken响应头；
