---
title: Hugo Theme Webstack
date: 2020-06-10T09:15:25+0800
tags: [折腾]
feature: https://lmm.elizen.me/images/2020/05/webstack-12.png
---

新版本更新，感谢 [@ooiii](https://github.com/bolabola/stackf) 改进，所有内容（导航和板块）的增删排序直接在 `links.toml` 内完成！ 👍

在线预览：<https://edui.fun/>

仓库下载：<https://github.com/lmm214/hugo-theme-webstack>

<!--more-->

### 配置说明

Hugo 站点 `config.toml` 默认配置，新增各信息和功能的修改。

```
theme = "webstack"
version = "20.06.09"

# 首页网址
baseURL = "https://edui.fun"
# 标题
title = "Edui.fun"

[params]
    # 副标题
    subtitle = "让教学有点意思"
    # 横条logo
    logo = "https://cdn.jsdelivr.net/gh/lmm214/edui@gh-pages/images/avatar.png"
    # logo 图标
    logoM = "https://cdn.jsdelivr.net/gh/lmm214/edui@gh-pages/images/eduifuns.png"
    # css和js文件的cdn
    cdn = "https://cdn.jsdelivr.net/gh/lmm214/edui@gh-pages"
    # 开启今日诗词
    jinrishici = "true"
    # 开启访问量统计
    busuanzi = "true"
```

### 主题使用

主题目录：
```
hugo-webstack
├── data
│   └── links.toml  //只需更改这里
├── layouts
│   └── home.html //独一无二一个页面搞定
└── theme.toml
```

`links.toml` 示例：

```
[[list]]
tag = '在线工具'
css = 'icon-globe'

[[list.sub]]
tag = '教学助手'
css = 'icon-star'

[[list.sub.item]]
description="随时随地打开，开启专注力训练"
siteLink="https://edui.fun/schulte/"
siteLogo="https://cdn.jsdelivr.net/gh/lmm214/images/logos/schulte.png"
siteName="舒尔特方格"

[[list.sub]]
tag = '图文影音'
css = 'icon-pencil'

[[list.sub.item]]
description="在线生成并打印描字帖、笔顺描写贴和常用字体模板"
siteLink="https://tool.lu/copybook/index.html"
siteLogo="https://cdn.jsdelivr.net/gh/lmm214/images/logos/toollu.png"
siteName="字帖生成器"

[[list]]
tag = '实用软件'
css = 'icon-desktop'

[[list.item]]
description="一键部署新版本 Office 全家桶，免费！"
siteLink="https://otp.landian.vip/zh-cn/"
siteLogo="https://cdn.jsdelivr.net/gh/lmm214/images@master/logos/otp.png"
siteName="Office Tool Plus"


[[list]]
tag = '移动在线'
css = 'icon-mobile'

[[list.item]]
description="在线电子教材、必备古诗词、24点出题"
siteImage="https://cdn.jsdelivr.net/gh/lmm214/images/logos/exzz.jpg"
siteLogo="https://cdn.jsdelivr.net/gh/lmm214/images/logos/exzz.jpg"
siteName="二小智造"
```

`list` 为主导航，`list.sub` 子导航，其中 `item` 中如果有 `siteImage` 则开启图片模式，效果如下：

![webstack-11](https://lmm.elizen.me/images/2020/05/webstack-11.png)

### 其他

部署参考：[Hugo + Github Actions 实现自动化部署](https://immmmm.com/hugo-github-actions/)

😈