#!/bin/bash

# 判断参数
if [ x$1 == x ];then
	echo '未传入参数，请输入文章slug，用中划线(-)分隔'
    exit 1
fi

filename=$1
today=$(date +"%F")
post_file=${today}-${filename}.md

hugo new posts/${post_file}
