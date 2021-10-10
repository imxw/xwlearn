---
title: Centos7上安装elasticsearch-6.2.2及相关插件
date: 2018-12-31T12:57:00+08:00
lastmod: 2018-12-31T12:57:00+08:00
featuredImage: "https://images.unsplash.com/photo-1554306274-f23873d9a26c?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=750&q=80"
---

elasticsearch是一个开源的搜索服务器，提供了一个分布式多用户能力的全文搜索引擎，下面是我的安装笔记

## 准备工作
### java版本
jdk版本必须是1.8及1.8以上

```bash
[root@localhost ~]# java -version
java version "1.8.0_161"
Java(TM) SE Runtime Environment (build 1.8.0_161-b12)
Java HotSpot(TM) 64-Bit Server VM (build 25.161-b12, mixed mode)
```
### 创建es用户
elasticsearch6 不允许root用户安装和使用，需要另外创建用户
```bash
[root@localhost ~]# useradd es &&  echo "es123"  | passwd --stdin es
```

### 修改 /etc/security/limits.conf
```bash
[root@localhost ~]#  vim /etc/security/limits.conf
# 修改系统最大文件描述符限制
* soft nofile 262144 
* hard nofile 262144
# 修改系统锁内存限制
es soft memlock unlimited 
es hard memlock unlimited
# 更改用户可启用的最大线程数
*  hard    nproc   4096
*  soft    nproc   4096
```
### 修改 /etc/sysctl.conf
```bash
[root@localhost ~]#  vim /etc/sysctl.conf
vm.max_map_count = 262144
vm.swappiness = 1   # 禁用swapping
```
使修改生效
```
[root@localhost ~]#  sysctl -p
```

## 安装 elasticsearch-6.2.2
### 下载解压
```bash
[root@localhost ~]# cd /usr/local/src
[root@localhost src]# wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.2.tar.gz
[root@localhost src]#  tar xzvf elasticsearch-6.2.2.tar.gz
[root@localhost src]# mv elasticsearch-6.2.2 /opt
```

### 修改elasticsearch-6.2.2目录权限

将该目录下所有文件的属主与属组均改为es
```bash
[root@localhost src]# chown -R es:es /opt/elasticsearch-6.2.2/
```

### 创建数据目录与日志目录
**注意：后续操作需要切换至es账户**
```bash
[root@localhost src]# su - es
[es@localhost src]$ cd /opt/elasticsearch-6.2.2/
[es@localhost elasticsearch-6.2.2]$ mkdir -p elasticsearchdata/{data,log}
```
### 修改配置文件

```bash
[es@localhost elasticsearch-6.2.2]$ cd /opt/elasticsearch-6.2.2/conf
[es@localhost conf]$  vim elasticsearch.yml
# 需要修改 cluster.name，node.name，path.data等参数值
cluster.name: app_es	# 集群名字
node.name: node-1	# 节点名字
path.data: /opt/elasticsearch-6.2.2/elasticsearchdata/data # 指定数据存放路径
path.logs: /opt/elasticsearch-6.2.2/elasticsearchdata/log # 指定日志存放路径
bootstrap.memory_lock: false
network.host: 0.0.0.0 # Set the bind address to a specific IP
http.port: 9200	# 默认是9200，你也可以通过修改其值自定义端口
transport.tcp.port: 9300    # 默认是9300，可自定义
# 集群发现
#集群节点ip或者主机，在这里添加各节点ip
discovery.zen.ping.unicast.hosts: ["ip1:9300", "ip2:9300"，"ip3:9300"]
# 设置这个参数来保证集群中的节点可以知道其它N个有master资格的节点。默认为1，对于大的集群来说，可以设置大一点的值（2-4）
discovery.zen.minimum_master_nodes: 3
```
### 启动服务

```bash
[es@localhost elasticsearch-6.2.2]$ /opt/elasticsearch-6.2.2/bin/elasticsearch    #前台启动
[es@localhost elasticsearch-6.2.2]$ nohup /opt/elasticsearch-6.2.2/bin/elasticsearch &    #后台启动
```

### 测试服务是否启动成功

看到9200和9300端口就ok了,其中9300是es节点tcp通讯端口,9200是RESTful接口

```bash
[es@localhost ~]$ netstat -lntp | grep -E "9200|9300"
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
tcp        0      0 0.0.0.0:9200            0.0.0.0:*               LISTEN      1022/java
tcp        0      0 0.0.0.0:9300            0.0.0.0:*               LISTEN      1022/java
```

在浏览器输入 http://你的ip:9200，可看到如下内容

```bash
{
  "name" : "node-1",
  "cluster_name" : "app_es",
 "cluster_uuid" : "...", 
  "version" : {
    "number" : "6.2.2",
    "build_hash" : "10b1edd",
    "build_date" : "2018-02-16T19:01:30.685723Z",
    "build_snapshot" : false,
    "lucene_version" : "7.2.1",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
证明启动成功
```
## 解决启动报错

### 错误一：Cannot allocate memory

>  Java HotSpot(TM) 64-Bit Server VM warning: INFO: os::commit_memory(0x00000000ca660000, 899284992, 0) failed; error='Cannot allocate memory' (errno=12)
> There is insufficient memory for the Java Runtime Environment to continue.
> Native memory allocation (mmap) failed to map 899284992 bytes for committing reserved memory.
> An error report file with more information is saved as:
> /opt/elasticsearch-6.2.2/hs_err_pid17955.log

由以上错误信息可知，分配给java的内存不足，elasticsearch6.2 默认分配 jvm 空间大小为1g，这个虚机的内存大小不足，需要修改 jvm 空间分配，我们可以将1g改成512m

```bash
[es@localhost ~]$ vim /opt/elasticsearch-6.2.2/config/jvm.options
-Xms1g  修改为 -Xms512m
-Xmx1g	修改为 -Xmx512m
```
### 错误二：文件描述符不足

```
ERROR: [3] bootstrap checks failed
[1]: max file descriptors [65535] for elasticsearch process is too low, increase to at least [65536]
[2]: memory locking requested for elasticsearch process but memory is not locked
[3]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```
如何你按我的教程顺序来就不会发生这个错误，请参照准备工作这一节，修改相应的内核参数

### 错误三：不能以root启动

不能以root身份来启动es服务，需要以相应的es来启动

## 插件下载

### 下载中文分词器 elasticsearch-analysis-ik 插件

```bash
[es@localhost ~]$ /opt/elasticsearch-6.2.2/bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.2.2/elasticsearch-analysis-ik-6.2.2.zip
```
### 下载 elasticsearch-head 插件
head插件是elasticsearch的客户端工具
```bash
# 下载必要组件
[root@localhost ~]# yum -y install nodejs npm git bzip2
[root@localhost ~]# cd /opt/
[root@localhost opt]# git clone https://github.com/mobz/elasticsearch-head.git
[root@localhost opt]# npm install -g grunt-cli
[root@localhost opt]# cd /opt/elasticsearch-head
[root@localhost /opt/elasticsearch-head]# npm install
# 修改Gruntfile.js
[root@localhost opt]# cd /opt/elasticsearch-head
[root@localhost /opt/elasticsearch-head]# vim Gruntfile.js
# 在appcss后添加server块
appcss: {
                                src: fileSets.srcCss,
                                dest: '_site/app.css'
                        },
                        server: {
                                options: {
                                        hostname: '*',          
                                        port: 9100,
                                        base: '.',      
                                        keepalive: true
                                }
                        }
                },
## 对外开放端口为9100，允许任何主机访问
# 修改elasticsearch-head默认连接地址
## 修改head/_site/app.js，修改head连接es的地址（修改localhost为本机的IP地址）
[root@localhost /opt/elasticsearch-head]#  cd _site
[root@localhost _site]# vim app.js
## 将localhost修改为es服务的IP地址
修改前：this.base_uri = this.config.base_uri || this.prefs.get("app-base_uri") || "http://localhost:9200";
修改后： this.base_uri = this.config.base_uri || this.prefs.get("app-base_uri") || "http://你的ip:9200";
# 启动head服务
[root@localhost _site]# cd /opt/elasticsearch-head/node_modules/grunt/bin/
[root@localhost bin]# nohup ./grunt server &
# 修改 elasticsearch-6.2.2 配置文件
[root@localhost opt]# su - es 
[es@localhost opt]$ vim /opt/elasticsearch-6.2.2/config/elasticsearch.yml
## 在配置文件最后添加下面两条
http.cors.enabled: true	# 允许跨域访问，为了配合elasticsearch-head可视化ES界面
http.cors.allow-origin: "*"	# 允许所有地址跨域访问
## 然后重启es服务
```
在浏览器输入：http://你的ip:9100，开始使用es服务吧
