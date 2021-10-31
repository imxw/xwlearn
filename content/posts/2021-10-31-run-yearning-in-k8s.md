---
title: "在k8s上部署Yearning"
authors: []
description: ""

tags: []
categories: []
series: []

code:
  maxShownLines: 100
  

featuredImage: "https://images.unsplash.com/photo-1524522173746-f628baad3644?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=1531&q=80"
featuredImagePreview: ""

---

## 什么是 Yearning

[Yearning](https://github.com/cookieY/Yearning)是一款开源的 MySQL SQL 审核平台，拥有 SQL 审核、审计，用户权限管理等功能，可以大大减少运维或 DBA 的工作量，同时也满足操作留痕的需求，方便后续的问题排查追踪。

具体介绍及使用见[官方文档](https://guide.yearning.io/)

## 前提条件

- 准备好kubernetes集群，自己试玩的话用 k3s 和 minikube 也可
- 准备好MySQL实例
- 准备好Docker构建环境


## 制作 Docker 镜像

官方提供的镜像只是用于简单的容器部署，离部署至 k8s 上还差点意思，所以我自己做了个。不过只上传至我司私有镜像仓库中，有需用的朋友可以自己根据如下 Dockerfile 自己做一个。

首先下载官方提供的二进制文件：<https://github.com/cookieY/Yearning/releases>

```bash
cd /tmp
wget https://github.com/cookieY/Yearning/releases/download/2.3.5/Yearning-2.3.5-linux-amd64.zip
unzip Yearning-2.3.5-linux-amd64.zip && cd Yearning-2.3.5-linux-amd64
```
包含文件如下：
```bash
.
├── #\ README
├── Dockerfile
├── Yearning
├── conf.toml
└── docker-compose.yml
```
除了`Yearning`这个二进制文件与`conf.toml`外，其他请删除，默认`conf.toml`文件暂时不用管，等会再说


新建`Dockerfile`文件如下
```
FROM alpine:3.12
EXPOSE 8000

COPY Yearning  /opt/Yearning
COPY conf.toml /opt/conf.toml

RUN echo "http://mirrors.ustc.edu.cn/alpine/v3.12/main/" > /etc/apk/repositories && \
      apk add --no-cache tzdata libc6-compat && \
      ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
      echo "Asia/Shanghai" >> /etc/timezone && \
      echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

WORKDIR /opt
```

构建镜像
```
docker build -t ${repo_addr}/${namespace}/yearning:2.0.0 .
docker push ${repo_addr}/${namespace}/yearning:2.0.0
```
{{< admonition open=true >}}
标签请写上自己的私有仓库全称，这里仅是示意。
{{< /admonition >}}

## 创建数据库

用如下语句创建 Yearning数据库，此处命名为：`yearning`
```sql
CREATE DATABASE IF NOT EXISTS yearning DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
```

## 创建配置文件

我们不用镜像中那个配置文件，而是通过 k8s 的`Secret`挂载至容器中

将自带的那个`conf.toml`按如下要求修改下
```toml
[Mysql]
Db = "yearning"   # 改为你所创建的数据库的名称
Host = "x.x.x.x"  # 建议填写数据库内网 ip地址
Port = "3306"  # MySQL 实例端口号
Password = "" # 数据库相应账户密码
User = "root"  # 数据库账户，建议新建一个 yearning 账户，只给 yerning 数据库权限

[General]
SecretKey = "dbcjqheupqjsuwsm" # 不用用默认那个，自己写一个，用于 JWT
Hours = 4 # 可自定义过期时间
```

制作 secret
```bash
cd /tmp/Yearning-2.3.5-linux-amd64  # 这里是我之前创建的目录，可以按自己需求创建
# 修改完 conf.toml 后做如下操作
kubectl create namespace yearning # 务必提前创建好命名空间
kubectl create secret generic mysql-secret --from-file=./conf.toml -n yearning # 在 yearning 命名空间创建 mysql-secret 
```
检查创建结果
```bash
> kubectl describe secret mysql-secret -n yearning
Name:         mysql-secret
Namespace:    yearning
Labels:       <none>
Annotations:  
Type:         Opaque

Data
====
conf.toml:  211 bytes
```


## Deployment 资源清单

可以将资源清单写在一起，这里为了方便展示分开写了

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: yearning
  name: yearning-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: yearning
  template:
    metadata:
      labels:
        app: yearning
    spec:
      containers:
      - image: xxxxxxx/yearning:2.0.0  # 这里替换你的 yearing镜像地址
        name: yearning
        command: ["sh"]
        args: ["-c", "/opt/Yearning install && /opt/Yearning run"]
        ports:
        - name: http
          containerPort: 8000
        readinessProbe:
          httpGet:
            path: /
            port: http
            scheme: HTTP
          initialDelaySeconds: 25
          periodSeconds: 2
        livenessProbe:
          httpGet:
            path: /
            port: http
            scheme: HTTP
          initialDelaySeconds: 30
          periodSeconds: 2
        resources:
          requests:
            cpu: 200m
            memory: 1Gi
          limits:
            memory: 2Gi
            cpu: 250m
        volumeMounts:
        - mountPath: /opt/conf.toml   
          name: secrets
          subPath: conf.toml  # 在这里挂载我们创建的 conf.toml，通过 subPath 的形式
          readOnly: true
      volumes:
      - name: secrets
        secret:
          secretName: mysql-secret
```

部署至 k8s
```bash
kubectl apply -f yearning-deploy.yml -n yearning
```

部署完毕获取相应的 pod 名
```bash
kubectl get pods -n yearning
```

## service 资源清单

```yaml
apiVersion: v1
kind: Service
metadata:
  name: yearning
  labels:
    app: yearning
spec:
  ports:
  - port: 8000
    name: http
    targetPort: http
  selector:
    app: yearning
```

部署至 k8s
```bash
kubectl apply -f yearning-service.yml
```

检查部署成功与否
```bash
kubectl port-forward svc/yearning  8000:8000 -n yearning
```

浏览器访问`http://127.0.0.1:8000`检查是否可进入登录界面


## ingress 资源清单

我们当然希望能够通过域名访问，那就需要用到 ingress 了。假设你有一个主域名`yearning.com`，希望通过子域名`sql.yearning.com`访问 yearning。

假如你申请了 ssl 证书，下载解压后文件有`xxx__yearning.com.pem`和`xxx__yearning.com.key`，按如下方式创建 secret
```yaml
kubectl create secret tls yearning-tls --cert=xxx__yearning.com.pem --key=xxx__yearning.com.key -n yearning
```

然后创建`yearning-ing.yaml`文件
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: yearning
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: 'true'
spec:
  tls:
  - hosts:
    - sql.yearning.com
    secretName: yearning-tls  # 请提前创建好 ssl 证书的 secret，如果不需要 ssl，可以去掉 tls 配置
  rules:
  - host: sql.yearning.com
    http:
      paths:
      - path: /
        backend:
          serviceName: yearning
          servicePort: http
```

部署至 k8s
```bash
kubectl apply -f yearning-ing.yml -n yearning
```

获取 ip 地址
```yaml
> kubectl get ing yearning -n yearning           
NAME       CLASS    HOSTS             ADDRESS        PORTS     AGE
yearning   <none>   sql.yearning.com   x.xx.xx.xxx   80, 443   167d
```
将 ADDRESS 对应的 ip 值解析至`sql.yearning.com`即可，接下来就可以正式在浏览器中通过地址`https://sql.yearning.com`访问 yearning 了


