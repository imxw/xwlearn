---
title: "如何批量删除离线的 GitLab Runner"
authors: []
description: ""

tags: [GitLab]
categories: []
series: []
ruby: true

featuredImage: "https://images.unsplash.com/photo-1531030874896-fdef6826f2f7?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=1170&q=80"
featuredImagePreview: ""
---

我司使用 GitLab CI 实现持续集成，之前想在 k8s 集群中部署 [GitLab Runner]^(相当于 GitLab CI 的 agent)[^1]，结果 Pod 不断重启，使得大量离线的 Runner 被注册到 GitLab 中，查找 runner 时略影响效率。虽然对 GitLab 总体使用影响不大，但作为一个强迫症，必须除之而后快。可惜 GitLab 界面上并没有批量删除按钮，倒可以一个一个删，但这上百个 runner，纯手删的话，简直是折磨，也没找到相关接口，所以我只好暂时放下了。
![](https://tva1.sinaimg.cn/large/008i3skNly1gvctufzs4cj61010l1q3x02.jpg)

后来对接 GitLab，又把这个事给拾起来了，只因每次操作 GitLab，看到这个界面就非常不爽。这次也终于如愿清理了它们，具体实现如下。

我们使用`python-gitlab`模块提供的`gitlab`命令行工具。

### 下载`python-gitlab`

```bash
pip install --upgrade python-gitlab
```

### 编写`.python-gitlab.cfg`

也可写在`/etc/python-gitlab.cfg`，本次写在`~/.python-gitlab.cfg`中

示例
```ini
[global]
default = somewhere
ssl_verify = false
timeout = 5

[somewhere]
url = https://some.whe.re
private_token = vTbFeqJYCY3sibBP7BZM
api_version = 4

[elsewhere]
url = http://else.whe.re:8080
private_token = helper: path/to/helper.sh
timeout = 1
```

- `[global]`下`default`是指命令行选项`--gitlab`没有指定 GitLab Server 的话，默认启用下面哪一节(如`[somewhere]`、`[elsewhere]`)
- `url` 填写自托管的 GitLab 的域名
- `private_token`从用户设置中获取

![](https://tva1.sinaimg.cn/large/008i3skNly1gvcuinung3j30xb0guwff.jpg)

创建并获取 token 后，填写到上述文件相应字段下即可。

### 清理 runner

```bash
for i in {4..428};do echo $i; gitlab runner delete --id $i;done
```
是不是很简单，`gitlab`CLI也没有提供批量删除命令，使用 shell 中 for 循环逐个删除就好了。

至于 id，如何获取呢，每注册一个 runner，其id 编号+1，前三个都是正常的，所有从 4 开始，最后一位编号是 428（可在界面上点击进入相应 runner 详情，从 url 中查看）。

![](https://tva1.sinaimg.cn/large/008i3skNly1gvcuqli9u8j60zr08e3ys02.jpg)

终于只剩下这三个正常的了。

[^1]: 可直接使用 GitLab 本身的 kubernetes 集成功能下载 Gitlab Runner