---
title: "为 obsidian 中的文件批量添加 front matter"
authors: []
description: ""

tags: [obsidian]
categories: []
series: []

featuredImage: ""
featuredImagePreview: "https://obsidian.md/images/screenshot.png"

---

## 什么是 front matter

`front matter`的中文意思是**前言**，几乎每本书都会有**前言**，用来说明写书目的或者内容总结。

而 markdown 文件中的`front matter`指的是以`yaml`格式在文件开头增加的元数据，示例如下：

```markdown
---
title: "为 obsidian 中的文件批量添加 front matter"
date: 2021-10-17 15:56
tags:
- obsidian
- frontmatter
---
```

{{< admonition  open=true >}}
`front matter`需要用`---`包裹
{{< /admonition >}}

笔记软件或博客软件会拿到这些元数据做相应处理，比如上面这个`front matter`中 `title` 字段用来作为文章题目，`date`作为发布日期，`tags` 作为文章的标签列表

## 什么是`obsidian`

![](https://obsidian.md/images/screenshot.png)
这里是指一款用于知识管理的笔记软件，支持双链、本地存储、插件、vim 模式、关系视图等，具体介绍见[官网](https://obsidian.md)

## 什么是`dataview`

是`obsidian`上一款优秀的插件，可用类似于`SQL`一样的语句去查询`obsidian`中的文档，从而实现统计分析。

## 为什么要添加 front matter

![](https://tva1.sinaimg.cn/large/008i3skNly1gvies2f6ojj614e0nwjtc02.jpg)

我使用 obsidian 软件已近一年，积累了不少笔记，在使用`dataview`插件做统计时发现一个问题：文件的创建时间不准。比如上图中这些文件很早就创建了，显示创建时间却是最近，而且这几个文件创建时间竟然一致，肯定有问题。

去查看文件实际创建时间才发现，和获取的是一样的，并无问题。

那到底是哪里出问题了呢？

因为我是基于 git 做同步的，比如在公司新建了几个文件，但是回家后并没有立即打开 obsidian 做同步，过了几天再拉下最新的文件，文件创建时间肯定变成当天了，而且是同时拉下来的，创建时间肯定一致了。

问题发现了，怎么解决呢？`front matter`就能解决这个问题。

可以在文件开头增加如下内容：

```markdown
---
create_date: 2021-09-17 17:31
---
```
相当于给每个文件写死了创建时间，统计时基于`front matter`中这个`create_date`字段即可。

于是，**最近创建的十篇文档**的`dataview`统计语句便由
{{< highlight markdown >}}
```dataview
table WITHOUT ID
  file.link AS "title",
  file.ctime as "time"
sort file.ctime desc
limit 10
```
{{< / highlight >}}

变成了

{{< highlight markdown >}}
```dataview
table WITHOUT ID
  file.link AS "title",
  create_date as "time"
sort create_date desc
limit 10
```
{{< / highlight >}}

那么问题又来了？统计问题是解决了，如何去添加`front matter`呢？不会是手动吧。

当然不是。

## 具体实现

### 增量文档

使用`Templater`插件制作`front matter`模板

```markdown
---
create_date: <% tp.file.creation_date() %>
---
```

配置新建文件时基于该模板创建，那么每次都会自动给文件添加带`create_date`的`front matter`了

### 存量文档

`Templater`当然也支持给存量文档添加`front matter`，但是存量文档有六百多篇，用手动的方式实在太累了，于是我写了一个 Python 脚本，实现批量在`front matter`中添加`create_date`与`tags`字段。

#### 下载`python-frontmatter`

```bash
pip install python-frontmatter
```

模块使用见[使用文档](https://python-frontmatter.readthedocs.io/en/latest/)

#### 编写脚本

```python
# coding: utf-8

import os
import re
import time

import frontmatter

# 更新md文件的front matter：1.增加创建时间；2.提取tag
def update_front_matter(file):

    with open(file, 'r', encoding='utf-8') as f:
       post = frontmatter.loads(f.read())
    
    is_write = False
    
    if not post.metadata.get('create_date', None):
        timeArray = time.localtime((os.path.getctime(file)))
        post['create_date'] = time.strftime("%Y-%m-%d %H:%M", timeArray)
        if not is_write:
            is_write = True
    
    # 将代码块内容去掉
    temp_content = re.sub(r'```([\s\S]*?)```[\s]?','',post.content)
    # 获取tag列表
    tags = re.findall(r'\s#[\u4e00-\u9fa5a-zA-Z]+', temp_content, re.M|re.I)
    ret_tags = list(set(map(lambda x: x.strip(), tags)))
    print('tags in content: ', ret_tags)
    print('tags in front matter: ', post.get("tags", []))
    if len(ret_tags) == 0:
        pass
    elif post.get("tags", []) != set(ret_tags): 
        post['tags'] = ret_tags
        if not is_write:
            is_write = True
    
    if is_write:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(frontmatter.dumps(post))

# 递归获取提供目录下所有文件
def list_all_files(root_path, ignore_dirs=[]):
    files = []
    default_dirs = [".git", ".obsidian", ".config"]
    ignore_dirs.extend(default_dirs)

    for parent, dirs, filenames in os.walk(root_path):
        dirs[:] = [d for d in dirs if not d in ignore_dirs]
        filenames = [f for f in filenames if not f[0] == '.']
        for file in filenames:
            if file.endswith(".md"):
                files.append(os.path.join(parent, file))
    return files


if __name__ == "__main__":
    # file_path = './xwlearn/test.md'
    # update_front_matter(file_path)
    ignore_dirs = ["Resource", "Write"]
    files = list_all_files('./xwlearn/', ignore_dirs=ignore_dirs)

    print("current dir: ", os.path.dirname(os.path.abspath(__file__)))
    for file in files:
        print("---------------------------------------------------------------")
        print('current file: ', file)
        update_front_matter(file)
        time.sleep(1)

```

{{< admonition tip "如何匹配 tag">}}
使用正则表达式，凡是`#+字符`均设为tag，但是有一个问题，代码块中有不少注释信息也会被匹配到，这就需要我们先忽略代码块中内容

```python
temp_content = re.sub(r'```([\s\S]*?)```[\s]?','',post.content)
```
匹配tag 的正则(`空格#中文字符与英文字符`)
```python
re.findall(r'\s#[\u4e00-\u9fa5a-zA-Z]+', temp_content, re.M|re.I)
```
{{< /admonition >}}

{{< admonition tip "如何递归文件及忽略目录">}}
使用`os.walk`遍历文件，并不是每个文件都需要添加`front_matter`，如果需要忽略某目录，就给`list_all_files`函数第二个参数传递相应的目录名，如上述脚本第 59 行，我 忽略了`Resource`与`Write`目录

```python
def list_all_files(root_path, ignore_dirs=[]):
    files = []
    default_dirs = [".git", ".obsidian", ".config"]
    ignore_dirs.extend(default_dirs)

    for parent, dirs, filenames in os.walk(root_path):
        dirs[:] = [d for d in dirs if not d in ignore_dirs]
        filenames = [f for f in filenames if not f[0] == '.']
        for file in filenames:
            if file.endswith(".md"):
                files.append(os.path.join(parent, file))
    return files

```
{{< /admonition >}}