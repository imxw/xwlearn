---
title: "一个 jar 包启动脚本"
date: 2018-12-27T18:30:00+08:00
slug: start-up-script-of-jar-package
toc: true
---


一个启 jar 包的脚本，你希望它还能有什么功能？

我希望它还能**停止**，**重启**，**上线**，**回滚**，能**查看运行状态**，能**查看日志**，于是有了下面这个脚本。

### 如何使用？

```bash
# 在你放脚本的地方执行下面这条命令下载脚本，本例是放在root目录下
[root@localhost ~]# curl -s https://devops.xwlearn.com/shell/boot-jar.sh > boot-jar.sh

# 查看使用帮助
[root@localhost ~]# bash boot-jar.sh 
========================================================================
 usage: boot-jar.sh [option] ... [start | stop | status | restart | log | upgrade]
 bash boot-jar.sh start        : start service			# 启动服务
 bash boot-jar.sh stop         : stop service			# 停止服务
 bash boot-jar.sh status       : service status			# 查看运行状态
 bash boot-jar.sh log          : service log			# 查看日志
 bash boot-jar.sh restart      : restart service		# 重启服务
 bash boot-jar.sh upgrade/up   : upgrade service		# 更新包
 bash boot-jar.sh rollback/back: rollback service		# 回滚包
========================================================================

# 修改变量

[root@localhost ~]# vim boot-jar.sh 
UPLOAD_PATH=                    		# 上包目录，如/opt/upload
DEPLOY_PATH=            				# jar包安装路径,如/opt/test
PACKAGE_NAME= 							# jar包名,如test-hello-1.0.0.jar
SERVICE_NAME=${PACKAGE_NAME%-*}         # 去掉后缀及版本号,本例为test-hello
LOG_NAME=${SERVICE_NAME}.log            # 日志名，本例为test-hello.log
ACTIVE="test"                           # 启动相应环境配置，如test|pre|pro
PACKAGE_PATH=$DEPLOY_PATH/$PACKAGE_NAME # 安装包路径,本例为 /opt/test/test-hello-1.0.0.jar
LOG_PATH=$DEPLOY_PATH/logs/$LOG_NAME    # 日志路径,本例为 /opt/test/logs/test-hello.log
BACKUP_PATH=$DEPLOY_PATH/backup         # 备份目录,本例为 /opt/test/backup
BACKUP_LAST=$(find $BACKUP_PATH -name "${PACKAGE_NAME}*" | xargs ls -t | head -1)
BACKUP_LAST_NAME=$(basename $BACKUP_LAST)  # 上一个备份包文件名
......

# 按照上面例子，需提前创建好相关目录

上包目录	/opt/upload
jar包安装目录	/opt/test
日志目录	/opt/test/logs
备份目录	/opt/test/backup

# 这里利用花括号的扩展功能快速创建目录及子目录，下面脚本中会有花括号另一个妙用

[root@localhost ~]# mkdir -p /opt/{upload,test/{logs,backup}}
[root@localhost ~]# tree /opt
[root@vultr ~]# tree -L 2 /opt
/opt
├── test
│   ├── backup
│   └── logs
├── upload
...

# 把你的jar包放入 /opt/upload 就行了

[root@localhost ~]# bash boot-jar.sh upload		# 上包并启动服务
[root@localhost ~]# bash boot-jar.sh status		# 查看运行状态

# 还可以把你的脚本目录放入path，就可以全局执行了

[root@localhost ~]# chmod u+x boot-jar.sh
[root@localhost ~]# vim /etc/profile.d/boot-jar.sh
export PATH="$PATH:/root"
[root@localhost ~]# source /etc/profile.d/boot-jar.sh
[root@localhost ~]# boot-jar.sh upload		# 上包并启动服务
[root@localhost ~]# boot-jar.sh status		# 查看运行状态
[root@localhost ~]# boot-jar.sh log		        # 查看日志
......
```
在展示完整脚本前，我先介绍下它的几个亮点。



### 如何判断某程序是否安装？

```bash
# 比如 java 
[root@localhost ~]#  command -v java
```
#### 为什么用 command 判断？而非 which

command 是 bash 内置命令，性能更好; 而 which 是外部命令，性能低些，这还不是主要的，我们来看看这两个命令的定义：

>Run command with args suppressing the normal shell function lookup. Only builtin commands or commands found in the PATH are executed
> If either the  -V or  -v  option  is  supplied, a description of command is printed
> ......
> If the -V or -v option is supplied, the exit status  is  0  if  command  was found, and 1 if not. 

由上可知，command是运行系统真正的命令，而非别名。换种说法，你先查看下你的`ls`命令别名

```bash
[root@localhost ~]# alias ls
alias ls='ls --color=auto'
```
所以说你键入`ls`命令时，实际运行的是`ls --color=auto`，假如有人把`ls`变成`rm -rf  /`，你是不是该跑路了？

command命令能让你只运行真正的`ls`，而非其别名。其`-v`选项是打印给定命令的简要描述，是别名的输出别名，不是的打印其命令路径，内置命令就输出其名称。更重要的是，它明确告诉你，如果找到了命令，就退出0，找不到就退出1，我们就利用这点判断系统是否安装某命令，注意，如果你安装了某应用，但是没有把它加入PATH，那就没法判断了。

再来看看which
> shows the full path of (shell) commands
>
> Which returns the number of failed arguments, or -1 when no `programname´ was given

which 主要是用来寻找命令的完整路径，其返回值是失败参数个数，也就是说which后面可跟多个参数，都找到了就返回0，失败一个返回1，失败n个返回n。没有给定参数，返回-1，也就是255，这是因为exit只能使用0~255之间的值，-1 的unsigned值便是255。

看起来好像which也能根据返回状态码判断某程序是否安装？但是which是外置命令，不同系统上的which实现方式是不一样的，很多系统上的which甚至不设置退出状态码，这样不管你找没找到某程序，都返回0，请问你如何判断？

除了command，type和hash这两个内置命令也可以判断，具体请看[stackoverflow](https://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script/677212#677212)

#### 写成函数

```bash
function check_cmd() {

    command -v $1  >/dev/null 2>&1 || { echo >&2 " \033[31m  $1 is not installed.  Aborting. \033[0m"; exit 1; }

}
```
这里的花括号其实是一个匿名函数，所以里面的语句末尾都得加分号。在[这里](https://www.cnblogs.com/yasmi/articles/5129571.html)查看更多shell中括号的总结

### 如何获得运行程序的pid？

通常做法是

```bash
PID=$(ps -ef |grep -v grep |grep <keyword> |awk '{print $2 }')
```
这种方法不是不能用，但是我觉得不够优雅，最优雅的方式是使用pgrep命令，上述命令可以改成

```bash
PID=$(pgrep -f <keyword>)
```
> The pattern is normally only matched against the process name.  When -f is set, the full command line is used.
> The running pgrep or pkill process will never report itself as a match

### 如何获得上一条命令的最后一个参数？

命令行中可以用!$，这是与`history`命令相关的特殊变量，脚本中就不可以这样了，通用做法是`$_`，命令行和脚本中都可以。这个是我自己试出来了的，墙内还没找到相关资料，刚刚为了印证，才翻了墙找了找，果然如我所料。

```bash
mkdir test && cd $_    # 创建test目录并进入
# 通常我们进入目录前最好判断该目录是否存在，可以用 []、[[]]以及test来进行条件测试，但知道了$_后，我通通改成下面这样，因为用了 [ ] 和 [[ ]] 就不能使用$_
test -d test && cd $_
# 万一不存在test目录，而我们希望创建后然后又进去，该如何做呢？
test -d test && cd $_ || mkdir $_ && cd $_ 
# 这就有点多余了，我们来优化下
test -d test  || mkdir $_ && cd $_ 
# 扩展，删除文件时我们也会判断下某文件是否存在，比如
[ -f /usr/local/src/justfortest.md ] && rm -f /usr/local/src/justfortest.md
# 这就显得臃肿了，我们来优化下
test -f /usr/local/src/justfortest.md && rm -f $_
```


### 完整脚本
```bash
#!/bin/bash

UPLOAD_PATH=						# 上包目录
DEPLOY_PATH=						# 安装路径
PACKAGE_NAME=						# 包名
SERVICE_NAME=${PACKAGE_NAME%-*}		# 切割包名，去掉后缀及版本号
LOG_NAME=${SERVICE_NAME}.log		# 日志名
ACTIVE="test"						# 运行环境 test|pre|pro
PACKAGE_PATH=$DEPLOY_PATH/$PACKAGE_NAME	# 安装包路径,如果是war的话, 改为$DEPLOY_PATH/webapps/$PACKAGE_NAME，$DEPLOY_PATH 值为tomcat路径，如/data/tomcat
LOG_PATH=$DEPLOY_PATH/logs/$LOG_NAME	# 日志路径
BACKUP_PATH=$DEPLOY_PATH/backup			# 备份目录
BACKUP_LAST=$(find $BACKUP_PATH -name "${PACKAGE_NAME}*" | xargs ls -t | head -1)
BACKUP_LAST_NAME=$(basename $BACKUP_LAST)

RETVAL="0"

function check_ok() {

        if [ $? != 0 ] 
        then
            echo -e "\033[31m ERROR! $1 \033[0m"
            exit 1
        fi  
}

function check_cmd() {

    command -v $1  >/dev/null 2>&1 || { echo >&2 " \033[31m  $1 is not installed.  Aborting. \033[0m"; exit 1; }

}

function get_pid() {

    PID=$(pgrep -f $PACKAGE_NAME)
}

function backup() {

local TIMESTAMP=$(date +%F-%H-%M)

    test -d $BACKUP_PATH || mkdir -p $_
    test -f $PACKAGE_PATH && mv -b  $_ $BACKUP_PATH/${PACKAGE_NAME}_${TIMESTAMP}   
}

function upload() {


    test -d $UPLOAD_PATH || mkdir -p $_

# 判断上包目录是否存在新包
    if [ -f $UPLOAD_PATH/$PACKAGE_NAME ];then
# 关服务
    stop

check_ok "stop $SERVICE_NAME"
# 判断安装目录是否存在

    test -d $DEPLOY_PATH || mkdir -p $_ 
    backup

    mv $UPLOAD_PATH/$PACKAGE_NAME $DEPLOY_PATH
# 起服务
    start

    else 

	echo -e " \033[31m there is no new package in $UPLOAD_PATH \033[0m"
	exit 1
    fi
}

function rollback() {

# 停服务
stop
# 删除安装目录中的包
test -f $PACKAGE_PATH && rm -f $_
# 回滚上一个包
test -f $BACKUP_PATH/$BACKUP_LAST_NAME && mv $_ $PACKAGE_PATH
# 起服务
start
}



function start() {

# 先判断java是否存在
    check_cmd java

#local  PID=$(pgrep -f $PACKAGE_NAME)

    get_pid

    if [ ${PID} ]; then
    echo -e  " $SERVICE_NAME is running, please run \033[34m $0 stop \033[0m first"
    exit 1
    fi

# 先判断日志文件是否存在
	
    test -d $DEPLOY_PATH/logs || mkdir -p $_ 

    cd $DEPLOY_PATH/logs

    test -f $LOG_NAME || touch $_
# 判断安装目录中是否有包

    test -f $PACKAGE_PATH || { echo "there is no package in $_";exit 1;}

    nohup java -jar $PACKAGE_PATH --spring.profiles.active=$ACTIVE  > $LOG_PATH 2>&1 &

    check_ok "running java -jar ..."

    echo -e  "$SERVICE_NAME \033[34m Started \033[0m"

    echo  -e "查看日志命令：\033[34m $0 log \033[0m 或者 \033[34m  tail -f $LOG_PATH \033[0m"
}

function stop() {

#local  PID=$(pgrep -f $PACKAGE_NAME)

    get_pid

    if [ ${PID} ]; then
    echo $SERVICE_NAME 'Stop Process'[${PID}]
    kill -15 $PID
    fi

    sleep 5
    
# local  PID=$(pgrep -f $PACKAGE_NAME)

    get_pid

    if [ ${PID} ]; then
        echo $SERVICE_NAME' Kill Process'[${PID}]
        kill -9 $PID
    else
        echo $SERVICE_NAME' Stop Success!'
    fi
}

function status(){

#local  PID=$(pgrep -f $PACKAGE_NAME)

    get_pid

    if [ "$PID" != "" ]; then
        echo -e "$SERVICE_NAME is \033[34m Running \033[0m [$PID] "
    else
        echo -e "$SERVICE_NAME is \033[31m Stopped \033[0m "
    fi
}

function log(){

	tail -100f $LOG_PATH
}

function usage(){

   echo "========================================================================================"
   echo -e "\033[34m usage: $0 [option] ... [start | stop | status | restart | log | upgrade]\033[0m"
   echo -e "\033[34m bash $0 start \033[0m       : start service"
   echo -e "\033[34m bash $0 stop \033[0m        : stop service"
   echo -e "\033[34m bash $0 status \033[0m      : service status"
   echo -e "\033[34m bash $0 log \033[0m         : service log"
   echo -e "\033[34m bash $0 restart \033[0m     : restart service"
   echo -e "\033[34m bash $0 upgrade/up\033[0m   : upgrade service"	# 升级服务
   echo -e "\033[34m bash $0 rollback/back\033[0m: rollback service"	# 回滚服务
   echo "========================================================================================"

   

   RETVAL="2"
}

RETVAL="0"

case "$1" in
    start)
	get_pid
	if [ $PID ];then
        echo -e " $SERVICE_NAME is running, please run \033[34m $0 stop \033[0m or \033[34m $0 restart \033[0m"
        else
	start
	fi
        ;;
    stop)
	echo "will stop $SERVICE_NAME"
        stop
        ;;
    restart)
	echo "will stop $SERVICE_NAME"
	stop
	echo "will start $SERVICE_NAME"
	start
        ;;
    upgrade|up)
	echo "will upgrade $SERVICE_NAME"
	upload
        ;;
    log)
        log
        ;;
    status)
        status
        ;;
    rollback|back)
	echo "will rollback to the last version"
        rollback
        ;;
    *)
       usage 
        ;;
esac

exit $RETVAL
```
