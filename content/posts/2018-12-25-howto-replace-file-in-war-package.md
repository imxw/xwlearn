---
title: "如何替换jar/war包里的文件"
date: 2018-12-25T10:14:00+08:00
lastmod: 2018-12-25T10:14:00+08:00
slug: howto-replace-file-in-war-package
---

### 要替换的文件在包的根目录

```shell
# 如要替换 test.war 包里的 test.xml
[xuwu@localhost ~]$ jar uvf test.war test.xml
```
### 要替换的文件在包的其他目录

```shell
# 如果不知道想改的文件在哪个目录，可以用 grep 查看下
[xuwu@localhost ~]$ jar tvf test.war | grep application.yml
   507 Tue Dec 25 09:45:48 CST 2018 WEB-INF/classes/application.yml

## 解压该文件,该目录下会生成该文件的目录结构
[xuwu@localhost ~]$ jar xvf test.war
[xuwu@localhost ~]$ ll
drwxrwxr-x 3 xuwu xuwu     4096 12月  6 21:54 META-INF
drwxrwxr-x 4 xuwu xuwu     4096 12月  6 21:54 WEB-INF

## 修改 WEB-INF/classes/application.yml 修改的内容，然后替换 war 包相应文件
[xuwu@localhost ~]$ jar uvf test.war WEB-INF/classes/application.yml

```

### 扩展

- 可以把与环境相关的文件直接放在服务器上，上线时用服务器本地的文件替换，防止开发打错包
- 增量打包，很多时候开发只是修改其中一个文件，没必要重新打包，直接替换该文件即可

### jar 常见用法

```shell
# 解压 .jar/.war 文件到当前目录
jar -xvf file.jar

# 列出 .jar/.war 文件内容
jar -tf file.jar

-v 在标准输出中生成详细输出
-u 更新现有文件
-c 创建新归档文件
-f 指定归档文件名
-x 解档文件
-t 列出归档文件内容
-0  仅存储; 不使用任何 ZIP 压缩（把jar包放进war必须把这个参数加上）
```
