---
title: "利用Jupyter Notebook打造go及python交互式编程环境"
date: 2019-06-02T21:17:00+08:00
lastmod: 2019-06-02T21:17:00+08:00
featuredImage: "https://images.unsplash.com/photo-1550645612-83f5d594b671?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=750&q=80"
---

## 先说说Jupyter Notebook
Jupyter Notebook既是一款笔记应用，又是一款交互式编程工具，号称支持运行40种编程语言。之前受李笑来在GitHub上的项目--[自学是一门艺术](https://github.com/selfteaching/the-craft-of-selfteaching)影响，下过一次，玩了玩，不过当时鲁钝，并未识得其好。近来，突然醒悟，这真是一款学习编程的好工具。

比如python。单纯用命令行python解释器的话，无法实现命令补全，用IPython的话，虽然能实现命令补全，但是笔记又得借助其他软件，二者是割裂的，下次想修改那段代码，想看效果，你又得拷到IPython中。

那么IDE怎么样呢？确实能实现实时查看代码执行效果，可以利用注释做笔记，但是当你的代码量变多了，而你只是想运行其中一部分代码的时候，你是注释其他代码还是另起一个新文件呢？而且IDE一般都很臃肿，打开速度都挺慢。综合以上，关于代码的学习笔记，我都选择用Jupyter。

以上是我近期使用Jupyter得来的一点浅识。看看大佬怎么说的。

> 从2017年开始，已有大量的北美顶尖计算机课程，开始完全使用Jupyter Notebook作为工具。比如李⻜⻜的CS231N《计算机视觉与神经网络》课程，在16年时作业还是命令行Python的形式，但是17年的作业就全部在Jupyter Notebook上完成了。再如UC Berkeley的《数据科学基础》课程，从17年起，所有作业也全部用 Jupyter Notebook完成。
> 
> 而Jupyter Notebook 在工业界的影响力更甚。在Facebook，虽然大规模的后台开发仍然借助于功能⻬全的IDE，但是几乎所有的中小型程序，比如内部的一些线下分析软件，机器学习模块的训练都是借助于Jupyter Notebook完成的。据我了解，在别的硅谷一线大厂，例如Google的AI Research部⻔Google Brain，也是清一色地全部使用Jupyter Notebook，虽然用的是他们自己的改进定制版，叫 Google Colab。

以上两段文字引自Fackbook资深工程师景霄在极客时间上的课程《Python核心技术与实战--02讲JupyterNotebook为什么是现代Python的必学技术》。下面这个图片中的代码同样引自该课程。

![](http://ww4.sinaimg.cn/large/006tNc79ly1g3n1fh589cj30oy0d2zlr.jpg)

总之，知道Jupyter Notebook真的很方便很实用就行了。下面总结下如何在Jupyter Notebook上安装python内核与go内核。如下操作均是在macOS系统上操作完成。

## python交互式编程

Jupyter本来就是因为python而诞生的，所以搞python内核很容易。如果你之前装了IPython，直接下载jupyter就行了。

```bash
# 安装python3
$ brew install python3
# 安装pip
$ curl https://bootstrap.pypa.io/get-pip.py | python3
# 安装ipython(如果出现权限问题，可以试试pip3 install ipython --user)
$ pip3 install ipython
# 安装jupyter
$ pip3 install jupyter
# 启动jupyter
$ jupyter notebook
```
执行启动命令后，会自动打开你的浏览器，本地链接为：http://localhost:8888/tree，你也可以在启动时使用 `--port`指定端口

![](http://ww4.sinaimg.cn/large/006tNc79ly1g3n36ir7boj30rq09cjsp.jpg)

![](http://ww2.sinaimg.cn/large/006tNc79ly1g3n39wpsa4j30rd063408.jpg)

使用起来很简单，就不做过多介绍了。文件后缀为`ipynb`，你可以使用git管理你的笔记，上传到远程仓库GitHub上，可以直接渲染该文件。

![](http://ww4.sinaimg.cn/large/006tNc79ly1g3n4da1adyj30ru0hwmze.jpg)


## golang交互式编程

go内核的安装稍微麻烦点。

```bash
# 安装go
$ brew install go
$ go version
go version go1.12.4 darwin/amd64

# 安装Jupyter Notebook
$ pip3 install jupyter

# 安装ZeroMQ
$ brew install zmq
# 我这里遇到的坑是创建软链时提示/usr/local/lib不可写，原来该目录属主是root，改成个人账户就行了
# 假如你用Mac或Linux把属主改成当前用户就行了
$ sudo chown -R roy:admin /usr/local/lib
# 然后按照之前的提示重新链接文件
$ brew link zeromq

# 配置环境变量，我用的zsh，修改.zshrc; bash的话修改.bashrc
$ vim ~/.zshrc
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
export GOPATH=/Users/roy/go 
# 使配置生效
$ source ~/.zshrc

# 利用pkg-config获取libzmq所有编译相关的信息
$ pkg-config --cflags libzmq

# 安装go内核(利用go get从github上下载gophernotes)
$ go get -u github.com/gopherdata/gophernotes 
$ mkdir -p ~/Library/Jupyter/kernels/gophernotes
$ cp $GOPATH/src/github.com/gopherdata/gophernotes/kernel/* ~/Library/Jupyter/kernels/gophernotes

# 将gophernotes加入PATH
$ vim ~/.zshrc
export PATH=$GOPATH/bin:$PATH
# 使配置生效
$ source ~/.zshrc

# 启动jupyter
$ jupyter notebook
```

好了，你可以在Jupter上愉快地玩go了。以上操作基于Mac，其他操作系统的安装可以参考[官方文档](https://github.com/gopherdata/gophernotes)
