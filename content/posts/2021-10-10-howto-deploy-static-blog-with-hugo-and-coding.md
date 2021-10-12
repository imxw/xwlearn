---
title: "使用hugo与coding部署静态博客"
tags: [hugo,blog,折腾]
featuredImagePreview: https://images.unsplash.com/photo-1497864149936-d3163f0c0f4b?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=1169&q=80
---

## 背景
今年过年期间将几乎荒废的站点迁移至 hugo，没写几篇，上个月再把站点迁移至国内，然后备了个案，选了个新主题--[DoIt](https://hugodoit.pages.dev/zh-cn/)，准备重新开张，故有此文。


## 名词解释 
- **静态博客**: 利用静态网站生成器（如 hexo，hugo 等）将文章编译成 html、css、js 等静态文件，可利用 GitHub Pages、OSS 等托管，好处是不需要另外购买服务器。

- **hugo**: Go 编写的一款高性能静态网站生成器。

- **coding**: 腾讯旗下代码托管平台，类似于 GitHub、GitLab、Gitee 等。

- **Markdown**：一种轻量级标记语言，可理解为简化版 html，常被程序员用于编写文档，实际上写文章用 markdown 最爽，专注于内容，无需纠结格式（珍爱生命，远离 Word）。

- **Git**：一款开源的代码版本管理工具，常为程序员所用，实际上可以管理一切纯文本，写文章时佐以 markdown，甚佳。

- **cos**: 腾讯旗下对象存储产品，相当于阿里的 OSS，可存储图片、视频、pdf 等文件，也可托管站点。

## 思路

1. 利用 markdown 编写文章
2. 利用 hugo 将文章编译成静态文件
3. 将静态文件推送至 coding 端远程 git仓库
4. coding 端将静态文件推送至 COS 端
5. 利用 CNAME 将 COS 相应域名映射至自己的域名

## 实现

### 利用hugo 生成站点

下载 hugo，示例为 Mac 端，其他端见[下载 hugo](https://gohugo.io/getting-started/installing/)
```bash
brew install hugo
```

查看 hugo版本
```bash
> hugo version
hugo v0.85.0+extended darwin/amd64 BuildDate=unknown
```

新建站点
```bash
hugo new site myblog
```

生成目录结构如下
```bash
> tree -L 1
├── archetypes
├── config.toml
├── content
├── resources
├── static
└── themes
```

- **archetypes**: 文章模板存储目录
- **config.toml**：站点配置文件
- **content**：文章、标签、分类等存放目录
- **static**：静态文件存储目录，如图片
- **themes**：博客主题存储目录

### 配置 DoIt 主题

下载主题
```bash
> cd myblog
> git init 
> git submodule add https://github.com/HEIGE-PCloud/DoIt.git themes/DoIt
```

开启主题
```bash
# 编辑 config.toml
theme  =  "DoIt"
```

其他配置见：<https://hugodoit.pages.dev/zh-cn/theme-documentation-basics/>

### 新增文章

使用 hugo 命令新增文章
```bash
> hugo new posts/just-for-test.md
```
默认情况下生成于`./content/posts/`目录下，会使用`archetypes`下的模板生成文章

### 本地查看

```bash
hugo serve
```
在浏览器直接访问<http://localhost:1313>即可访问站点，修改文章后也会实时更新，这样我们就能边写文章，边在本地浏览器上预览最终效果了。

### 静态文件生成


```bash
hugo
```

直接使用 hugo 命令即可，该命令会在 public 目录下生成网站最终的静态文件，如果希望其他人也能通过浏览器访问到，就需要一个公共服务来托管我们的静态文件，本次使用腾讯云的 COS。

### 静态文件托管


{{< mermaid >}}graph LR;
    A[登录 coding] --> B[新建项目] 
    B --> C[新建代码仓库]
{{< /mermaid >}}


将你本地项目的远程仓库指向 coding 新建的仓库

```bash
> hugo # 生成静态文件
> cd myblog/public # 进入静态文件目录
> git init # 初始化 git 项目
> git remote add origin  xxx.git # 添加远程仓库
> git add .
> git commit -m "xxx"
> git push -u -f origin master # 推送至远程 master 分支
```

接下来，开启网站托管
![](https://tva1.sinaimg.cn/large/008i3skNly1gvafugozo3j60y60ne3ze02.jpg)

部署成功后，可自定义域名，并开启 https
![](https://tva1.sinaimg.cn/large/008i3skNly1gvag5hkpt2j61bq0d53zc02.jpg)

接下来每次推送静态文件都会触发自动部署
