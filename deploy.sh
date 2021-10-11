#!/bin/bash

commit="update from hugo: $(date +"%F %T")"
current_dir=$(dirname $(readlink -f "$0"))
public_path=${current_dir}/public
email=$(git config --get user.email)
user=$(git config --get user.name)

config_git(){
    git config --global user.email "ixw1991@126.com"
    git config --global user.name "xuwu"
}


public_git(){
    git init
    git remote add origin git@e.coding.net:xwlearn/blog/blog.git
    git add .
    git commit "-m ${commit}"
    git push -u -f origin master
}
# 判断git配置
[ ${email} != "ixw1991@126.com" -o ${user} != "xuwu" ] && config_git
#[ ${email} != "ixw1991@126.com" ] && git config --global user.email "ixw1991@126.com"
#[ ${user} != "xuwu" ] && git config --global user.name "xuwu"

# 提交blog更改到远程blog分支
echo "将会将本地更改提交到远程blog分支"
echo "当前目录：$(pwd)";git pull origin blog && git status
#git add .; git status
#git commit -m "${commit}"
git push origin blog && echo "本地更改已提交至远程仓库blog分支"
git --no-pager log -n 1

# 判断public目录是否存在，存在则删除
[ -d ${public_path} ] && echo "开始删除${public_path}";rm -rf ${public_path}
# 生成html文件
echo "执行hugo生成html文件"
hugo

#操作public目录
cd ${public_path};echo "当前目录：$(pwd)"
public_git && echo "本地更改已提交至远程仓库master分支"
#git log -n 1
git --no-pager log -n 1
