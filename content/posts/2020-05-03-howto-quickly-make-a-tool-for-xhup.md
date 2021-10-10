---
title: "使用Python开发一款小鹤双拼编码查询工具"
slug: howto-quickly-make-a-tool-for-xhup
date: 2020-05-03T18:08:30+08:00
lastmod: 2020-05-03T18:08:30+08:00
tags: []
featuredImage: https://images.unsplash.com/photo-1521225753516-46438a76f25a?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=1074&q=80
---

学生生涯结束，踏入社会，没有成绩、学分约束，没有老师、学校监督，完全凭个人兴趣、意志自学的技能，挑出三个你最有成就感的。

你会选哪三个？

另外两个暂且不提，对于我来说，肯定会有[小鹤双拼](https://www.flypy.com)。

![小鹤双拼](https://www.flypy.com/images/hejp.png)

其实说「小鹤双拼」还不太准确，应该说「小鹤音形」。因为它不仅仅是一个双拼方案，还有双形方案。
>  双形即从每个字中提取首末两部分形态各异的组字单元，以区分同音字，组字单元即字根

![小鹤字根](https://www.flypy.com/images/hebu.png)

比如「**武**」字，拆分是:`一戈止`，首字根是`一`(形码是 a，笔画中「横」对应 a)，末字根是`止`(形码是 v，zh 对应 v)，完整的小鹤音形码是: 「**双拼+双形**」，即`wuav`。小鹤的字根基本都取声母，不需要特别记忆。所以，学起来也不难，主要是要多练习，形成肌肉记忆。
基本坚持学习一个月就能掌握「小鹤音形」，此后四码上屏，打字如飞。我的意外收获是:借机[学会了盲打](https://xwlearn.com/how-do-i-master-touch-type-in-two-hours/)，如虎添翼。

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gefk8r67w2g30fe06045x.gif)

尽管我已熟练掌握小鹤音形，但是偶尔部分字还是会忘记编码。这时，我希望手边有一个工具能够辅助我快速查询编码。有爱好者制作了一款**微信小程序**，不过因为**某些原因**，该小程序需要**看广告换积分**来查询。**pass**。

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gefmprjvc3j30ku112gm5.jpg)

另外还有一个[网站](http://react.xhup.club/search)可以查询编码。

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gefmvn90ggj30ie0hjaaa.jpg)

如果不想折腾，这里已经可以打住了，iOS 端只需要将该网页「**添加到主屏幕**」即可，参见[上篇文章](https://xwlearn.com/howto-graciously-bb-in-ios/)。

但我喜欢折腾，下面，我将说说我是如何利用该网站的接口自己开发了一款小鹤编码查询工具。

先说说如何找接口。使用谷歌浏览器访问该网站，然后按 F12 进入开发者模式，执行查询时会发现多了一个叫 searchCode 的请求。

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gefni8sbkkj318b0m677i.jpg)

这是一个 **POST** 请求，请求 URL 是 http://www.xhup.club/Xhup/Search/searchCode。

请求头如下

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gefo28zl6qj30l007qwev.jpg)

其中，**Host** 告诉后台，浏览器想访问的 web 服务器的**域名/IP 地址和端口号**，这里是 www.xhup.club。**Origin** 告诉后台请求发起方是 http://react.xhup.club，所以后面假如我们想用 Python 模拟该请求必须带上该头部，否则后台判定该请求不合法，后面响应头部中有个: `Access-Control-Allow-Origin: http://react.xhup.club`，意思是只接受 http://react.xhup.club 发起的请求。

再来看看这个 **Referer**，跟 Origin 类似，我们是访问 http://react.xhup.club/search 后再发起的查询请求，所以这里记录的是上一个页面的 URL(**协议+域名+查询参数**) 即是 http://react.xhup.club/search。另外，还需要注意这个 User-Agent，当我们用 Python 调该接口时需要带上该头部以欺骗后台服务: **请求是浏览器发起的**。

代码中请求头如下：
```python
headers = {
  'Origin': 'http://react.xhup.club',
  'Referer': 'http://react.xhup.club/search',
  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36',
  'Host': 'www.xhup.club',
  'Content-Type': 'application/x-www-form-urlencoded',
  'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
  'Accept': 'application/json, text/plain, */*',
}
```

接下来是最关键的一步了。

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gefomth3qcj30kx06ht8z.jpg)

我们执行查询时实际上是提交了一个表单，该表单包括**所要查询的汉字**与一个 **sign**。当表单上传编码格式为`application/x-www-form-urlencoded`，参数的格式（点击view source）如下

```
search_word=%E4%B8%AD&sign=fa8d52dc60388d70b092c7f34db8f0c2
```

其中，汉字需要进行百分号转义。那么这里的 sign 是从哪来的呢? 通常是一个 md5 值。我们来看下相关 js 代码，打一些断点调试。

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gefp7nk4q1j30hz057t8v.jpg)

![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gefpfpmovej30ej08674i.jpg)

图中变量 `e` 为 **key_xhup** 的值，即 **fjc_xhup**，变量 `r` 为 **search_word** 的值，即所要查询的汉字，`W()` 不用管，姑且猜测为 md5 加密函数，这里对 **fjc_xhup** 与 **search_word** 合并后的字符串进行了加密作为 **sign** 的值。

在浏览器查询「**中**」的编码时，**sign** 值为: **fa8d52dc60388d70b092c7f34db8f0c2**。下面我们用 Python 的 md5 测试下。

```python
In [1]: import hashlib

In [2]: key_xhup = 'fjc_xhup'

In [3]: search_word = '中'

In [4]: sign = hashlib.md5((key_xhup + search_word).encode('utf-8')).hexdigest()
   ...:

In [5]: print(sign)
fa8d52dc60388d70b092c7f34db8f0c2
```
猜测正确。好了，剩下的事情就非常简单了。

我分别用 [Pythonista](http://omz-software.com/pythonista/) 与苹果自带的[快捷指令](https://support.apple.com/zh-cn/guide/shortcuts/apdf22b0444c/2.2/ios/12.0)实现了该功能。其中，由于**捷径**的局限性，我设计为一次只能查询一个字的编码。

<photos>![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gefqadrulng30ku112nhs.gif)![](https://tva1.sinaimg.cn/large/007S8ZIlgy1gefqd474l8g30ku112kbp.gif)</photos>

- [完整代码](https://github.com/imxw/xhup/blob/master/xhup.py)
- [捷径下载](https://www.icloud.com/shortcuts/c3610835668145b5aa3436fc5c608dec)

