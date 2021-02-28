---
title: "如何在Mac上使用uTools优雅地bb？"
slug: howto-graciously-bb-in-mac
date: 2020-04-27T17:09:16+08:00
tags: []
draft: true
---

几天前看了少数派一篇教程「[保卫表达：用后端 BaaS 快速搭建专属无点赞评论版微博——b言b语 ](https://sspai.com/post/60024)」，顿时兴奋不已，这不正是我期盼已久的东西么。像新浪微博、之前 qq 空间里的说说以及现在的朋友圈，都有作者总结的如下问题。

> 1. 会被点赞、评论机制刺激分泌多巴胺，导致莫名兴奋、并对此产生期待。这些情绪不仅干扰后续表达，也带来了回复的社交压力；
> 2. 时间线+订阅的机制使我认为频繁发布无价值内容会打扰关注者；
> 3. 为避免引战、被攻击以及各种原因需要进行严格的自我审查；
> 4. 发布内容的路径长，经常被首页其他内容分散，浪费时间；

这些年，我逐渐在这些平台上"销声匿迹"，上述几个原因所占比重不可谓不大，毕竟我曾经也是文字表达欲极强的愤青一个，也被删过贴，也曾论过战，如今咬舌闭口，蒙眼塞耳，身困五斗稻粮谋，表达欲已然奄奄一息。所幸，照着作者教程搭完这个「私人微博」后，表达欲顿时重焕新生。

如果你也想有一个「无点赞评论私人微博」，至少需要做如下准备（具体可看[作者所写教程](https://sspai.com/post/60024)，非常详尽，我就不叠床架屋了）。
1. 注册 [leanCloud](https://leancloud.app) (有国际版与国内版，当然选国际版了，再慢也选)并新建应用。创建一个class，命名为content，接着创建一个column（列），同样命名为content。说白了，content class 就是一张表，而 content column(列)就是这张表里的一个字段，后续「b 言 b 语」前端数据的呈现就是对这张表里数据的渲染，而客户端的操作就是对这张表进行增删改查。
接下来在设置中找到你的关键认证信息。
![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ge8juns26xj30ut0atdgi.jpg)
找一个地方把这几个关键信息存下来，后面都会用到。
2. 注册 [GitHub](https://github.com)，并创建一个仓库，命名为: `用户名.github.io`，比如用户名为 bb，那仓库命名为:`bb.github.io`，利用的是 GitHub 提供的 Pages 服务，如果嫌慢，可以使用国内的码云、coding 托管。不过，我更愿意用 GitHub，原因你懂的。

3. 下载作者[仓库](https://github.com/daibor/nonsense.fun)中 index.html ，替换文件中的 AppID 与 AppKey，然后上传到你在 GitHub 上创建的仓库中。


做完以上三步，你的「私人微博」就搭建完成了，下面该考虑内容发布的事了。作者将平台命名为「b言b语」，索性我就将在该平台上发布内容称为bb了。Windows、iOS、安卓端都有现成的内容发布方案，唯独MacOS端没有。作为平日里的白嫖党，我也终于可以贡献一份力量了，于是有了下述方案。

内容发布其实就是调 leanCloud 接口在Content表中插入一条数据，常用的shell、Python都能实现，官方甚至有对应的SDK。不过在终端上总觉得不够优雅，我想整一个大众都能用的。思来想去，我想到了久未打开的uTools。用过Mac的，必然知道Splotlight，再进一步，必然知道传说中的Alfred。而uTools就是一款国人开发的类Alfred软件，上面有大量的生产力相关的插件工具，而且是免费的哦。

uTools上有一款插件叫：快捷命令。你可以用熟悉的编程语言编写脚本，然后通过uTools调用。

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ge8ogoeiv2j30s50gfq3o.jpg)

进入该插件后，可以新建一条命令。如下图所示，使用shell中curl命令调leanCloud接口发布信息。

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ge8poa121lj30m30i6gn0.jpg)


下面是Python版
![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ge8pve2fyoj30m30i13zc.jpg)

```python
#!/usr/local/bin/python3
# _*_ coding: utf-8 _*_

import urllib3
import json

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

data = {"content": "{{subinput}}"}

headers = {
    'Content-Type': 'application/json',
    'X-LC-Id': '',   # 填入AppID
    'X-LC-Key': ',master' # 逗号前填入masterKey
}

url = 'https://AppID前八位.api.lncldglobal.com/1.1/classes/content'

http = urllib3.PoolManager(timeout = 3)

r = http.request('POST', url, body=json.dumps(data), headers = headers)

if str(r.status) == "201":
    print('success!')
    print(json.loads(r.data.decode('utf-8')))
else:
    print('something is wrong!')
```

具体脚本内容及后续优化可在[仓库](https://github.com/imxw/bb)中找到

从上述描述可知，要发布的内容是通过uTools的变量传递到脚本中的。我只推荐其中两个变量，一个是`{{ClipText}}`即剪贴板中的文本，另一个是`{{subinput}}`，指的是子输入框文本，也是我最终采用的变量，可能不如剪贴板好理解，所以我做了一个动图。

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1ge8qh1ugbkg313s0d0azj.gif)

ok，让我们一起bb吧。
