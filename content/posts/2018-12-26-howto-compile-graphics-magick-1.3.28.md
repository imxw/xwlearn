---
title: 编译安装GraphicsMagick-1.3.28
date: 2018-12-26T17:25:00+08:00
lastmod: 2018-12-26T17:25:00+08:00
slug: howto-compile-graphics-magick
---

GraphicsMagick 号称为图像处理领域的瑞士军刀，下面是我的安装笔记，如果你想一键安装可以在命令行运行

```bash
curl -s https://devops.xwlearn.com/shell/gmagick.sh | bash 
source /etc/profile.d/gmagick.sh
```

## 系统版本
```bash
[root@localhost local]# uname -r
3.10.0-693.2.2.el7.x86_64
[root@localhost local]# cat /etc/redhat-release 
CentOS Linux release 7.4.1708 (Core) 
```

## 官网地址 
ftp://ftp.graphicsmagick.org/pub/GraphicsMagick/

## 下载版本
GraphicsMagick-1.3.28

## 下载依赖

```bash
yum install -y libjpeg-devel libjpeg
yum install -y libpng-devel libpng
yum install -y giflib-devel giflib
```

## 安装过程
```bash
# 下载
wget ftp://ftp.graphicsmagick.org/pub/GraphicsMagick/1.3/GraphicsMagick-1.3.28.tar.gz
# 解压
tar -zxvf GraphicsMagick-1.3.28.tar.gz 
cd GraphicsMagick-1.3.28
#编译
./configure --prefix=/usr/local/GraphicsMagick-1.3.28 --with-quantum-depth=8   --enable-shared --enable-static
make && make install
# 创建软链
ln -s /usr/local/GraphicsMagick-1.3.28  /usr/local/GraphicsMagick
```

## 设置环境变量

```bash
vim /etc/profile.d/gmagick.sh
export GMAGICK_HOME="/usr/local/GraphicsMagick"
export PATH="$GMAGICK_HOME/bin:$PATH"
LD_LIBRARY_PATH=$GMAGICK_HOME/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
```

> 生效配置 source /etc/profile.d/gmagick.sh

## 测试

```bash
gm convert -list formats
```

> 如果列表中显示PNG、JPEG、GIF等则表示已支持图片转换

## 一键安装脚本

我现在养成了一个习惯，每写一篇文档就会写一份相应的脚本，下面这个脚本已经在CentOS7和CentOS6环境测试过

```bash
#!/bin/bash

SRC_PATH=/usr/local/src		#源码安装目录
SRC_URL=ftp://ftp.graphicsmagick.org/pub/GraphicsMagick/1.3/GraphicsMagick-1.3.28.tar.gz		#源码地址
PACKAGE_NAME=$(basename $SRC_URL)   	# GraphicsMagick-1.3.28.tar.gz
PACKAGE_FILE=$(basename $PACKAGE_NAME .tar.gz) 		# GraphicsMagick-1.3.28
PACKAGE_NAME_PURE=${PACKAGE_FILE%-*}    		# GraphicsMagick
INSTALL_PATH=/usr/local		# 应用安装目录


check_ok() {
	if [ $? != 0 ] 
	then
	    echo -e "\033[31m ERROR! $1 \033[0m"
	    exit 1
	fi
}

check_yum() {
	if ! rpm -qa|grep -q "^$1"
	then
	    yum install -y $1
	    check_ok
	else
	    echo -e "\033[34m $1 already installed \033[0m."
	fi
}

deploy-gmagick() {

# 下载依赖，把需要的依赖放在一个数组里
arr_package=("libjpeg-devel" "libjpeg" "libpng-devel" "libpng" "giflib-devel" "giflib")

for package in ${arr_package[@]};do
	check_yum $package
done

# $_ 代表上一个命令最后一个参数

test -d $SRC_PATH  && cd $_  ||  mkdir -p $_ && cd $_ 

# 如果已经安装了就不需要下载了
if [ ! -f  $PACKAGE_NAME -a ! -d $PACKAGE_FILE ];then

wget $SRC_URL

check_ok "download $PACKAGE_NAME_PURE"

tar zxvf $PACKAGE_NAME 

check_ok "tar xf  $PACKAGE_NAME_PURE"

elif [ -f $PACKAGE_NAME -a ! -d $PACKAGE_FILE ];then

tar zxvf $PACKAGE_NAME

check_ok "tar xf  $PACKAGE_NAME_PURE"

else 

echo "you have installed $PACKAGE_FILE "

fi


cd $PACKAGE_FILE

./configure --prefix=$INSTALL_PATH/$PACKAGE_FILE --with-quantum-depth=8   --enable-shared --enable-static

check_ok "configure"

make && make install

check_ok "make install"

test -d $INSTALL_PATH  || mkdir -p $_ 

test -h $INSTALL_PATH/$PACKAGE_NAME_PURE && rm -f $_

ln -s $INSTALL_PATH/$PACKAGE_FILE $INSTALL_PATH/$PACKAGE_NAME_PURE

}

config-gmagick(){

# 利用 here document 创建环境变量
cat >> /etc/profile.d/gmagick.sh  << EOF
export GMAGICK_HOME="$INSTALL_PATH/$PACKAGE_NAME_PURE"
export PATH="\$GMAGICK_HOME/bin:\$PATH"
LD_LIBRARY_PATH=\$GMAGICK_HOME/lib:\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
EOF

source /etc/profile.d/gmagick.sh		# 如果用bash执行这个脚本的话，此处不会生效，需要手动在命令行重新执行一次 source /etc/profile.d/gmagick.sh

}

deploy-gmagick

check_ok "deploy-gmagick"

echo "start to configure GgraphMagick"

config-gmagick

[ $? == "0" ] && echo "SUCCESS"
```
