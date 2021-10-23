---
title: "如何在iOS端优雅地bb"
date: 2020-05-01T15:45:18+08:00
lastmod: 2020-05-01T15:45:18+08:00
tags: [bb]
featuredImagePreview: "https://images.unsplash.com/photo-1612128686557-71729cbcfe41?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=1190&q=80"
toc:
  enable: false
lightgallery: true
---


[上篇博文](https://xwlearn.com/howto-graciously-bb-in-mac) 介绍了如何利用 [leanCloud](https://leancloud.app) 及 [GitHub](https://github.com) 搭建一个 「[无赞无评论私人微博](https://sspai.com/post/60024)」并在 MacOS 端利用 [uTools](https://u.tools) 发布内容，今天说说 iOS 端如何发布内容。
>  其实 uTools 是一款跨平台效率工具，Windows 与 Linux 端都可以使用。

在iOS 端，[原作者 daibor](https://sspai.com/u/daibor/updates) 已经提供了一个「[捷径](https://www.icloud.com/shortcuts/3cfcbc36a6a24e0a8721bfeef8dfc6cf)」工具。如果不想再折腾了，其实已经够用了。

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gecz0iw4ifg30ku112wz1.gif)

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gecz42heewj309r0ezwek.jpg)

不过，我恰恰喜欢折腾。而且，苹果自带的「快捷指令」是面向大众的，操作简单，无需过多编程基础，就像搭积木一样组合功能。优点是上手简单，缺点是它不是一款专业的编程工具，它的简单在面向一些稍复杂点的需求时就不简单，比如调第三方接口的操作，显得异常繁琐。好在，iOS端还有一款专业级编程工具:
[Pythonista](http://omz-software.com/pythonista/)

![](http://omz-software.com/pythonista/images/DeviceScreenshots.png)

入手 Pythonista 差不多一年了，平日只看看作者提供的一些案例(近百个):数据分析类、动画类、游戏类、UI 类、Widget 类等等，直接在上面编程次数并不多，主要是没啥需求，这下有了需求，正好派上用场。

[代码](https://github.com/imxw/bb)如下：

```python

import requests
import time
import hashlib
import console
def main():

    text = console.input_alert(u'这次想bb点啥？')
    if not text:
        print('No text input found.')
        return
    appId = ' '  # 填入 LeanCloud 中的 AppID
    masterKey = ' '  # 填入 LeanCloud 中的 MasterKey
    timestamp = int(round(time.time() * 1000))

    ret = str(timestamp) + masterKey
    sign = hashlib.md5(ret.encode('utf-8')).hexdigest()
    data = {"content": text}

    headers = {
        'Content-Type': 'application/json',
        'X-LC-Id': appId,
        'X-LC-Sign': "{},{},master".format(sign, timestamp)

        }

    url = 'https://{}.api.lncldglobal.com/1.1/classes/content'.format(
        appId[:8])

    print(u'开始bb...')

    r = requests.post(url, json=data, headers=headers)

    print(u'bb中...')

    if r.status_code == 201:
        print(u'bb成功！')
        print(r.text)
    else:
        print(u'bb失败！')
        print(r.text)


if __name__ == '__main__':
    main()
```

按如下操作将脚本执行快捷方式保存在主屏幕并执行，执行效果看倒数第二张动图。

<photos>![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ged57ebql7j30ku112q46.jpg)![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ged58aflr0j30ku112jsu.jpg)![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ged59c00kzj30dz0ni74w.jpg)![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ged5aeznw3j30dv0ongm3.jpg)![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ged5bezyvcj30ku11275m.jpg)![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ged5fbuduej30ku112go9.jpg)![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ged1rwzstwg30ku112qkr.gif)![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ged42vdrmxj30ku0syt9b.jpg)</photos>

