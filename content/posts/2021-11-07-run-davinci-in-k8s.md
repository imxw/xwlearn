---
title: "在 k8s 中部署数据可视化工具 Davinci"
authors: []
description: ""

tags: []
categories: []
series: []

code:
  maxShownLines: 100

featuredImage: "https://images.unsplash.com/photo-1533406494543-e6cf6430f44a?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=1170&q=80"
featuredImagePreview: ""

---
## 什么是 Davinci

[Davinci](https://github.com/edp963/davinci)是宜信数据团队开源的一款 BI 产品。支持多种可视化图表，简单易用，懂 SQL 便可直接上手。

官方并未提供容器化部署方式，相关资料也较少，本人经过一番尝试，已成功在 k8s 集群中部署，现分享如下。

{{< admonition open=true >}}
Davinci 详细介绍及使用见[官方文档](https://edp963.github.io/davinci/docs/zh/1.1-deployment)
{{< /admonition >}}


## 前提条件

- 准备好kubernetes集群，自己试玩的话用 k3s 和 minikube 也可
- 准备好MySQL实例
- 准备好Docker构建环境


## 制作 Docker 镜像

官方并未提供 Docker 镜像，我定做了一个。

### java 镜像

{{< admonition open=true >}}
直接用 java 镜像的话，由于其基础镜像不是 centos，部署 chrome 及 chromedirver 会有问题，所有我干脆重新定做了 java 镜像
{{< /admonition >}}

先去官网下载 jdk-8u141-linux-x64.tar.gz，然后按如下`Dockerfile`定做 java 镜像
```
FROM centos:7

RUN cd / && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && yum makecache \
  && yum install -y wget aclocal automake autoconf  gcc gcc-c++ python-devel mysql-devel bzip2 libffi-devel epel-release \
  && yum clean all

WORKDIR /opt

ADD jdk-8u141-linux-x64.tar.gz /opt

ENV JAVA_HOME=/opt/jdk1.8.0_141
ENV CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
ENV PATH=$JAVA_HOME/bin:$PATH
CMD ["java", "-version"]
```

制作并推送到远程仓库
```bash
docker build -t registry-vpc.cn-beijing.aliyuncs.com/xxx/java:1.8.0 .
docker push registry-vpc.cn-beijing.aliyuncs.com/xxx/java:1.8.0
```

{{< admonition open=true >}}
标签请写上自己的镜像仓库全称，这里仅是示意。
{{< /admonition >}}

### Davince 镜像

先下载二进制文件
```bash
wget https://github.com/edp963/davinci/releases/download/v0.3.0-rc/davinci-assembly_0.3.1-0.3.1-SNAPSHOT-dist-rc.zip
```


`Dockerfile`文件如下
```
FROM registry-vpc.cn-beijing.aliyuncs.com/xxx/java:1.8.0 # 更换自己的基础镜像地址

COPY davinci-assembly_0.3.1-0.3.1-SNAPSHOT-dist-rc.zip /opt

RUN cd /opt && yum install unzip libX11 libXcursor libXdamage libXext libXcomposite libXi libXrandr gtk3 libappindicator-gtk3 xdg-utils libXScrnSaver liberation-fonts -y alsa-lib-devel vulkan \
    && wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm \
    && rpm -ivh google-chrome-stable_current_x86_64.rpm \
    && rm -rf google-chrome-stable_current_x86_64.rpm \
    && unzip davinci-assembly_0.3.1-0.3.1-SNAPSHOT-dist-rc.zip \
    && rm -rf davinci-assembly_0.3.1-0.3.1-SNAPSHOT-dist-rc.zip __MACOSX \
    && mv davinci-assembly_0.3.1-0.3.1-SNAPSHOT-dist-rc davinci \
    && wget https://chromedriver.storage.googleapis.com/80.0.3987.106/chromedriver_linux64.zip \
    && unzip chromedriver_linux64.zip \
    && mv chromedriver /usr/local/bin/ \
    && rm -rf chromedriver chromedriver_linux64.zip

ENV DAVINCI3_HOME /opt/davinci

WORKDIR /opt/davinci
```
{{< admonition open=true >}}
需要下载 chrome 与 chromedriver 用于截图
{{< /admonition >}}


构建镜像
```
docker build -t registry-vpc.cn-beijing.aliyuncs.com/xxx/davinci:0.3.1 .
docker push registry-vpc.cn-beijing.aliyuncs.com/xxx/davinci:0.3.1
```
{{< admonition open=true >}}
标签请写上自己的镜像仓库全称，这里仅是示意。
{{< /admonition >}}

唯一的问题就是做出来的镜像比较大，共 1.68G，不过好在能用。之前尝试用 alpine 来制作，总是以失败告终，缺得东西较多。

## 创建数据库

用如下语句创建 Davinci数据库，此处命名为：`davinci`
```sql
CREATE DATABASE IF NOT EXISTS davinci DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
```

## 创建配置文件

{{< admonition open=true >}}
请根据注释信息填写自己的配置
{{< /admonition >}}

创建`application.yaml`文件如下
```yaml

server:
  protocol: http
  address: 0.0.0.0
  port: 8080

  servlet:
    context-path: /

  # Used for mail and download services, can be empty, careful configuration
  # By default, 'server.address' and 'server.port' is used as the string value.
  access:
    address: xxx # 改为自己的域名地址，邮箱验证跳转时用到
    port: 80


## jwt is one of the important configuration of the application
## jwt config cannot be null or empty
jwtToken:
  secret: xxx  # 改为自己的 secret
  timeout: 1800000 # 改为自己的超时时间
  algorithm: HS512


## your datasource config
source:
  initial-size: 1
  min-idle: 1
  max-wait: 30000
  max-active: 10
  break-after-acquire-failure: true
  connection-error-retry-attempts: 1
  time-between-eviction-runs-millis: 2000
  min-evictable-idle-time-millis: 600000
  max-evictable-idle-time-millis: 900000
  test-while-idle: true
  test-on-borrow: false
  test-on-return: false
  validation-query: select 1
  validation-query-timeout: 10
  keep-alive: false
  filters: stat

  enable-query-log: false
  result-limit: 1000000


spring:
  mvc:
    async:
      request-timeout: 30s
  rest:
    proxy-host:
    proxy-port:
    proxy-ignore:


  ## davinci datasource config
  datasource:
    type: com.alibaba.druid.pool.DruidDataSource
    url: jdbc:mysql://xxx:3306/davinci?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull&allowMultiQueries=true&useSSL=false  # 改为自己的数据库地址
    username: xxx # 改为自己的数据库用户
    password: xxx # 改为自己的数据库密码
    driver-class-name: com.mysql.jdbc.Driver
    initial-size: 1
    min-idle: 1
    max-wait: 30000
    max-active: 10
    break-after-acquire-failure: true
    connection-error-retry-attempts: 1
    time-between-eviction-runs-millis: 2000
    min-evictable-idle-time-millis: 600000
    max-evictable-idle-time-millis: 900000
    test-while-idle: true
    test-on-borrow: false
    test-on-return: false
    validation-query: select 1
    validation-query-timeout: 10
    keep-alive: false
    filters: stat

  ## mail is one of the important configuration of the application
  ## mail config cannot be null or empty
  ## some mailboxes need to be set separately password for the SMTP service)
  mail:
    host: smtp.163.com 改为自己用到的邮箱 smtp，用于账号注册
    port: 465 # 改为自己邮箱 smtp 用到的端口
    username: xxx # 改为自己的邮箱账户信息，如下字段一样
    fromAddress: xxx
    password: xxx
    nickname: Davinci

    properties:
      smtp:
        starttls:
          enable: true
          required: true
        auth: true
      mail:
        smtp: 
          ssl:
            enable: true

screenshot:
  default_browser: CHROME
  timeout_second: 600
  chromedriver_path: /usr/local/bin/chromedriver   # 要与镜像中地址保持一致

data-auth-center:
  channels:
    - name:
      base-url:
      auth-code:

statistic:
  enable: true

```


{{< admonition open=true >}}
- 邮箱部分需要提前做好验证
- address需要改为0.0.0.0，让外部可访问
- access需要打开，其中address需要写服务的域名或ip，注册用户时激活地址用到该信息
- 数据源按照自己的信息填写
- screenshot需要下载chrome与chromedriver
{{< /admonition >}}


制作 secret
```bash
kubectl create namespace davinci # 务必提前创建好命名空间
kubectl create secret generic config-secret --from-file=./application.yml -n davinci # 在 davinci 命名空间创建 config-secret 
```

{{< admonition open=true >}}
- 配置文件不要写死在镜像中
- 涉及到敏感数据的配置信息不要放在 configmap 中，要放入 secret 中
{{< /admonition >}}


## Deployment 资源清单

可以将资源清单写在一起，这里为了方便展示分开写了

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: davinci
  name: davinci-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: davinci
  template:
    metadata:
      labels:
        app: davinci
    spec:
      containers:
      - image: registry-vpc.cn-beijing.aliyuncs.com/xxx/davinci:0.3.1  # 改为自己的镜像地址
        name: davinci
        command: ["java","-Dfile.encoding=UTF-8", "-cp", "$JAVA_HOME/lib/*:lib/*","edp.DavinciServerApplication"]
        ports:
        - name: http
          containerPort: 8080
        readinessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 200
          periodSeconds: 30
        livenessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 200
          periodSeconds: 30
        volumeMounts:
        - mountPath: /opt/davinci/config/application.yml
          name: secrets
          subPath: application.yml
          readOnly: true
      volumes:
      - name: secrets
        secret:
          secretName: config-secret

```

{{< admonition open=true >}}
- 镜像地址需要改为自己的
- 探针部分与资源配置部分可根据自己的需要更改
- 启动命令：`java -Dfile.encoding=UTF-8 -cp $JAVA_HOME/lib/*:lib/* edp.DavinciServerApplication`
- 通过存储卷挂载 secret 的方式更加安全
{{< /admonition >}}


部署至 k8s
```bash
kubectl apply -f davinci-deploy.yml -n davinci
```


## service 资源清单

```yaml
apiVersion: v1
kind: Service
metadata:
  name: davinci
  labels:
    app: davinci
spec:
  ports:
  - port: 8080
    name: http
    targetPort: http
  selector:
    app: davinci
```

部署至 k8s
```bash
kubectl apply -f davinci-service.yml -n davinci
```

检查部署成功与否
```bash
kubectl port-forward svc/davinci  8080:8080 -n davinci
```

浏览器访问`http://127.0.0.1:8080`检查是否可进入登录界面


## ingress 资源清单

证书 secret 的创建见[在 k8s 中部署 yearning](https://xwlearn.com/run-yearning-in-k8s/#ingress-资源清单) ，本篇不再赘述。

假设你有主域名`davinci.com`，并有 ssl 证书，且制作证书 secret 为`bi-tls`，本次需要用到的子域名为：`bi.davinci.com`

创建`davinci-ing.yaml`文件
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: davinci
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: 'true'
spec:
  tls:
  - hosts:
    - bi.davinci.com
    secretName: bi-tls  # 请提前创建好 ssl 证书的 secret，如果不需要 ssl，可以去掉 tls 配置
  rules:
  - host: bi.davinci.com
    http:
      paths:
      - path: /
        backend:
          serviceName: davinci
          servicePort: http
```

部署至 k8s
```bash
kubectl apply -f davinci-ing.yml -n davinci
```

获取 ip 地址
```yaml
> kubectl get ing davinci -n davinci         
NAME       CLASS    HOSTS             ADDRESS        PORTS     AGE
davinci   <none>   bi.davinci.com   x.xx.xx.xxx   80, 443   75d
```
将 ADDRESS 对应的 ip 地址解析至`bi.davinci.com`即可，接下来就可以正式在浏览器中通过地址`https://bi.davinci.com`访问 davinci了


