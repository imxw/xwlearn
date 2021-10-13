import os
import frontmatter

POST_DIR = './content/posts/'
DOMAIN = 'https://xwlearn.com'

# 递归获取提供目录下所有文件
def list_all_files(root_path, ignore_dirs=[]):
    files = []
    default_dirs = [".git", ".obsidian", ".config"]
    ignore_dirs.extend(default_dirs)

    for parent, dirs, filenames in os.walk(root_path):
        dirs[:] = [d for d in dirs if not d in ignore_dirs]
        filenames = [f for f in filenames if not f[0] == '.']
        for file in filenames:
            if file.endswith(".md"):
                files.append(file)
    return sorted(files,reverse=True)

def main():
    with open(POST_DIR + '2013-09-20-doggerel.md', 'r', encoding='utf-8') as f:
        post = frontmatter.loads(f.read())
        print(post)



if __name__ == '__main__':
    posts = list_all_files(POST_DIR)

    # post 字典列表
    post_list = []
    
    # 获取文章元数据
    for post in posts:
        temp_dict = {}

        with open(POST_DIR + post, 'r', encoding='utf-8') as f:
            content = frontmatter.loads(f.read())

        if content.metadata.get('draft', False) == True:
            continue
        temp_dict['title'] = content.metadata['title']
        split_post = post.split('-',3)
        temp_dict['date'] = '-'.join(split_post[:3])
        temp_dict['slug'] = split_post[-1].rstrip('.md')

        post_list.append(temp_dict)

    
    # 写入README
    with open('README.md', 'w', encoding='utf-8') as f:
        header = "## [习吾学]({})\n\n".format(DOMAIN)

        format_posts = []

        for post in post_list:
            temp = "[{}]({}/{})--{}\n".format(post['title'], DOMAIN, post['slug'], post['date'])
            format_posts.append(temp)
    
        body = "## 所有文章\n" + '- ' + '- '.join(format_posts)
        f.write(header + body)