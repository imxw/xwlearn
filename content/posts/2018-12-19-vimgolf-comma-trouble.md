---
title: "vim高尔夫解说之逗号问题"
date: 2018-12-19T22:16:00+08:00
lastmod: 2018-12-19T22:16:00+08:00
featuredImagePreview: https://images.unsplash.com/photo-1510915228340-29c85a43dcfe?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=750&q=80
fontawesome: true
---

vim 是 vi 编辑器的升级版，是 Linux <i class="fa fa-linux" aria-hidden="true"></i> 世界最为著名的一款文本编辑器，国外有个叫 [vimgolf](http://www.vimgolf.com) 的网站,将 vim 操作比作打高尔夫球，里面设计了很多挑战，你可以在那里测试、提高自己的 vim 水平。

那么，如何衡量你的vim水平？

最简单粗暴的方式就是计算击键数，修改同样一段文本，击键次数越少，水平越高，一键对应一分，即分数越少，水平越高。

下面这个挑战叫：[逗号问题](http://www.vimgolf.com/challenges/5ba020f91abf2d000951055c)

---

**初始文本**

```
,0,1,2,3,4,5,6,7,89
,1,2,3,4,5,6,7,8,90
,2,3,4,5,6,7,8,9,01
,3,4,5,6,7,8,9,0,12
,4,5,6,7,8,9,0,1,23
56,7,8,9,0,1,2,3,4,
67,8,9,0,1,2,3,4,5,
78,9,0,1,2,3,4,5,6,
89,0,1,2,3,4,5,6,7,
90,1,2,3,4,5,6,7,8,
```

**目标文本**

```
0,1,2,3,4,5,6,7,8,9
1,2,3,4,5,6,7,8,9,0
2,3,4,5,6,7,8,9,0,1
3,4,5,6,7,8,9,0,1,2
4,5,6,7,8,9,0,1,2,3
5,6,7,8,9,0,1,2,3,4
6,7,8,9,0,1,2,3,4,5
7,8,9,0,1,2,3,4,5,6
8,9,0,1,2,3,4,5,6,7
9,0,1,2,3,4,5,6,7,8
```
---

观察初始文本与目标文本差异可知，作者的目标是，除了第一列前和最后一列后无逗号，其余每一位数字均由`,`隔开，原始文本需要改的地方是：

- 前五行
	- 第一列逗号删掉
	- 最后一列两位数字用`,`分隔开
- 后五行
	- 第一列两位数字用`,`分隔开
	- 最后一列逗号删掉

知道了不同，现在就让我们瞄准目标，开始打vim高尔夫吧！ready go！


## 第一局：29分

第一局，我的得分是29分，也就是击了29键。既然是批量操作，我首先想到的是命令模式，该模式也被称为冒号模式，因为以冒号开头。

![](https://tva1.sinaimg.cn/large/008i3skNly1gvwkdzotgag307u074dgc.gif)


```bash
:1,5norm x$P<CR>
```

- 首先输入`:`进入`命令模式`，要操作前五行，需输入`1,5`，这里`1`也可以换成`.`，因为进入文件时，光标在第一行，`命令模式`中`.`代表`光标所在行`
- `norm`是`normal`的缩写（可以省两键），即`普通模式`，两个模式各有千秋，`普通模式`擅长近程攻击，操作范围窄；`命令模式`适合远程攻击，操作范围广，二者优势互补，珠联璧合。
- `norm`后空一格以输入`普通模式`命令，删(x)第一个字符（`,`），跳到行位(`$`在`普通模式`中是指作用到行尾)，在最后一个字符前粘贴(`P`)之前删掉的字符（`,`），按`<CR>`（Enter）键执行操作
- 至此，首轮操作完毕，光标跳到第5行倒数最后一个逗号上

![](https://tva1.sinaimg.cn/large/008i3skNly1gvwkfhfglwg307u074aan.gif)

```bash
:6,$norm $x0p<CR>ZZ
```

- 同样是在`命令模式`中调用`普通模式`，操作范围是第6行到最后一行，`$`在`命令模式`中代表最后一行。
- `$x`代表挑战到行尾，然后删掉最后一个字符（`,`），因为操作范围是最后五行，所以最后一列的逗号都会被删掉
- `0`代表绝对行首，也可以叫它硬行首，软行首是`^`,光标跳转到行首后，执行`p`，就会粘贴刚才删掉的逗号，删掉的字符会保存在寄存器中，大写的p在光标前粘贴寄存器中的字符，小写的p在光标后粘贴寄存器中的字符。按`<CR>`（Enter）键执行操作
- 至此全部修改完成，但是别忘了，我们还要**保存退出**的，这里用的是`ZZ`，还可以用`:wq`和`:x`，不过`命令模式`执行需要按`<CR>`（Enter）键，这样一来，`:wq`需要按四个键，`:x`需要按三个键，而`ZZ`只需要按两个键便可

## 第二局：26分

使用`命令模式`虽然简单易懂，但是局限也很明显，那就是无法再降低击键数了，这次我们换一个模式：`可视模式`，所谓`可视模式`其实还是在`普通模式`中，只不过可以像鼠标一样选中字符、行、块。

![](https://tva1.sinaimg.cn/large/008i3skNly1gvwkg0wt7rg307u074406.gif)

```bash
<C-V>4jx$<C-V>4jI,<Esc>6G<C-V>4jA,<Esc>$<C-V>4jdZZ
```

- `<C-V>`(ctrl+v)进入块选择模式，我们想操作前五行的第一列，就向下选中4行（执行`4j`），删除(`x`)第一列逗号;
- `$<C-V>4jI,<Esc>`，意思是跳到行尾，进入`可视化模式`，选中前五行最后一列，在选中列开头插入逗号，然后按`ESC`退出`插入模式`
- `6G<C-V>4jA,<Esc>`，意思是跳到第6行（`普通模式`中跳转到第n行，命令是nG），进入`可视化模式`，选中后五行第一列，在选中列末尾插入逗号，然后按`ESC`退出`插入模式`
- `$<C-V>4jdZZ`，意思是跳到行尾，进入`可视化模式`，选中后五行最后一列，然后删除该列，最后按`ZZ`保存退出

## 第三局：19分

第二次尝试虽然比第一次降低3次按键，但是还有很大的优化空间，我们先把他放在一边，这次我们换一种方式，利用 vim 的录制宏来操作。

![](https://tva1.sinaimg.cn/large/008i3skNly1gvwkh5sx1xg307u074q49.gif)

```bash
qa<C-V>4jx6G$q@a0p{$PZZ
```

- `qa`输完就代表开始录制了，接下来的操作`<C-V>4jx6G$`，先是删除前五行第一列第一个字符`,`
- 然后`6G`跳转到第6行，`$`跳转到该行尾部，`q@a`代表结束录制，然后重复一次刚才的操作，后五行最后一个字符便被删掉了
- `0p`回到第六行行首，并在第一列后粘贴刚才删掉的`,`
- `{`跳转到段首，这里便是第一行第一个字符，`$P`跳到行尾并在前一个字符前粘贴寄存器里内容，即`,`
- `ZZ`保存退出

## 第四局：14分

![](https://tva1.sinaimg.cn/large/008i3skNly1gvwkhgxd6zg307u074js0.gif)

```bash
<C-V>Mx$P}<C-V>4kx0pZZ
```

还记得第二局吧，现在我们来优化下
- `<C-V>Mx`进入可视化模式，选中前五行第一个字符并删掉，`M`代表屏幕中间行
- `P}<C-V>4kx`，`P`这里直接粘贴`,`，不用像之前那样还选中再粘贴，`}`跳到段尾，进入可视化模式，`4k`像上移动4行，即选中最后五行的最后一列，然后删掉(`x`)
- `0pZZ`跳到行首，直接`p`粘贴寄存器里的`,`，然后保存退出，一共才用14键
---
这是我能想出来的最少键数了，不过还有更变态的


## :(fa fa-thumbs-up): 终极操作：12分

![](https://tva1.sinaimg.cn/large/008i3skNly1gvwkhtmizag307u074mxs.gif)

```bash
qaxpeq98@aZZ
```

只有你的击键数足够少才能看到比你更少的，我玩到第四局才看到世界排名第一的操作，他是用录制宏的方式解决的

- `qa`开始录制宏，`xp`删掉第一个字符(`,`)，并将其粘贴到后面，`e`跳到词尾，即跳到刚才粘贴的那个逗号上，然后停止录制，重复98次上述操作
- 有个更变态的，其实只需要重复94次就可以了
