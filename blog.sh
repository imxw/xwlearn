#!/bin/bash

# 判断参数
if [ x$1 == x ];then
	echo '未传入参数，请输入文章slug，用中划线(-)分隔'
    exit 1
fi

filename=$1
today=$(date +"%F")
date=${today}T$(date +"%T%:z")
post_dir=content/posts
post_name=${today}-${filename}.md
post_path=${post_dir}/${post_name}

if [ $1 == 0 ];then
    post_name=${today}.md
    filename=${today}
    title=${today}
    post_path=${post_dir}/chat/${post_name}
fi

current_dir=$(dirname $(readlink -f "$0"))
full_post_path=${current_dir}/${post_path}

cat > ${post_path} <<EOF
---
title: "${title}"
slug: $filename
date: ${date}
tags: []
draft: false
---
EOF

echo "${full_post_path} created"
