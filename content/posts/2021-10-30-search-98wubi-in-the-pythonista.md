---
title: "利用 Pythonista 制作一款 98 五笔编码查询工具"
authors: []
description: ""
tags: []
categories: []
series: []

featuredImage: ""
featuredImagePreview: "http://omz-software.com/pythonista/images/DeviceScreenshots.png"

---

## 名词解释

- **[Pythonista](http://omz-software.com/pythonista/)**：是一款 iOS 端强大的 Python IDE，提供 Python2.7、Python3.6 解释器，包含大量常用模块，可用于 iPhone端及 iPad 端 Python 编程，之前我使用它[开发过小鹤编码查询工具](http://xwlearn.com/howto-quickly-make-a-tool-for-xhup/)。
- **98 五笔**：常用五笔分为：86 版、98 版及新世纪版，98版被称为是拆字最为和谐自洽，字根数量最多，击键协调性最好，对大字符集适应最好的一版

## 为什么要做这款工具

最近刚学 98五笔，拆字还不熟练，需要一款随时可查五笔编码的工具，没找到称手的，于是决定自己写一个。

主要实现功能如下：
- 展示单字简码，全码
- 展示单字拆解图
- 展示单字拼音

效果如下：

{{<image src="https://tva1.sinaimg.cn/large/008i3skNly1gvxhj7xib3j30ss0nf3zm.jpg" caption="查询效果" width="420" height="518">}}

## 具体实现

### 接口分析

使用[蛙蛙工具](https://www.iamwawa.cn/)的五笔编码查询接口：<https://www.iamwawa.cn/wubi.html>

以**藏**字为例，网页上请求
![](https://tva1.sinaimg.cn/large/008i3skNly1gvxeygn5caj31b10b03zj.jpg)

分析接口，可知点击查询按钮会发起两个请求，一个是获取编码，另一个是获取拆分图示。
![](https://tva1.sinaimg.cn/large/008i3skNly1gvxf2mprr2j31850gzju7.jpg)

分析响应，返回一个 json 字符串，其中 `c98j` 即是 98 简码，`c98` 是 98 全码，`py` 是拼音。
![](https://tva1.sinaimg.cn/large/008i3skNly1gvxf58avrkj31260ccgnh.jpg)

拆分图示地址：<https://www.iamwawa.cn/Data/wubi/藏.png>
![](https://tva1.sinaimg.cn/large/008i3skNly1gvxf6cg7kpj30uz0e5q4q.jpg)

接口分析完毕，那就开干吧。

### 脚本实现

主要用到 [Pythonista](http://omz-software.com/pythonista/) 中自带的`ui`、`console`、`markdown2`及`requests`库

```python
# coding: utf-8
import sys

import ui
import console
import requests
from markdown2 import markdown

TEMPLATE = '''
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width">
<title>Preview</title>
<style type="text/css">
body {
 font-family: helvetica;
 font-size: 15px;
 margin: 10px;
}
</style>
</head>
<body>{{CONTENT}}</body>
</html>
'''

def main():
 
    search_word = console.input_alert(u'想查哪个字的编码？')
    if not search_word:
        print('No text input found.')
        sys.exit(0)
 
    url = "https://www.iamwawa.cn/home/wubi/ajax"
 
    headers = {
        'Origin': 'https://www.iamwawa.cn',
        'Referer': 'https://www.iamwawa.cn/wubi.html',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36',
    }
  
    payload = {"hanzi": search_word}
  
    response = requests.post(url,headers=headers, data=payload)
 
    res_dict = {}

    if response.status_code == 200:
        data = response.json()
   
        if data['status'] == 1:
            res_dict = data['data'][0]
   
        else:
            print(response.json())
    else:
        print('请求异常')
        print(response.json())
        sys.exit(1)
 
    text = "# {}\n - 98简码: {}\n - 98编码: {}\n - 拼音: {}\n\n![](https://iamwawa.cn/Data/wubi/{}.png)".format(search_word,res_dict["c98j"],res_dict["c98"],res_dict["py"],search_word)
    converted = markdown(text)
    html = TEMPLATE.replace('{{CONTENT}}', converted)
    webview = ui.WebView(name='98 五笔编码查询')
    webview.load_html(html)
    webview.present()

if __name__ == '__main__':
    main()
```

## 最终效果

{{<image src="https://tva1.sinaimg.cn/large/008i3skNly1gvxg00r6soj30u01szqa7.jpg" caption="脚本" width="540" height="1170">}}
{{<image src="https://tva1.sinaimg.cn/large/008i3skNly1gvxg0qomggj30u01szn2l.jpg" caption="查询示例" width="540" height="1170">}}
{{<image src="https://tva1.sinaimg.cn/large/008i3skNly1gvxg11xvuaj30u01szac5.jpg" caption="查询效果" width="540" height="1170">}}
