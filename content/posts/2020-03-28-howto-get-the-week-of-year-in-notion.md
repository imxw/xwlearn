---
title: "如何在Notion中计算某日属于当年第几周？"
slug: howto-get-the-week-of-year-in-notion
date: 2020-03-28T19:59:19+08:00
lastmod: 2020-03-28T19:59:19+08:00
tags: [notion]

featuredImage: "https://images.unsplash.com/photo-1489844981779-7f06e8e0fdbb?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1189&q=80"
---

玩[Notion](https://www.notion.so/Notion-Official-83715d7703ee4b8699b5e659a4712dd8)已近一年，今天才知道怎么用最简单的方式轻松计算某日属于当年第几周。不过，也怪不得我啊，官方示例根本就没有，各个notion达人也没见哪一位提到这一点，下面说说我是怎么误打误撞发现的吧。


## 源起

几天前，看到[Linmi大佬](https://linmi.cc)的视频号在推一个「[2020年习惯打卡](https://www.notion.so/cnotion/2020-8fa0b3f42d2742c38440b3549de99b5b)」的模板，感觉不错，就去Notion中文社区找到了这个模板。一看，确实不错，美中不足的是周数是由人工填写的（对于直接使用该模板的人没啥影响，但对于制作者Melody来说就有些痛苦啦）。

![](https://ixwu.github.io/post-images/1585398195332.png)

本周视图是根据「周数」字段的值过滤（Filter）出来的，而「周数」字段值并非公式（Formula）计算得出。

![](https://ixwu.github.io/post-images/1585398214608.png)

也就是说，每新增一条「习惯打卡」就要手动填写这个「周数」字段值。下图中 `∑` 图标字段代表是由公式（Formula）计算得出。

![](https://ixwu.github.io/post-images/1585398269225.png)

Notion中公式有不少，可惜就是没有这个计算周数的。

![](https://ixwu.github.io/post-images/1585398229000.png)


当然，Notion支持csv导入，先在excel中用相应公式处理下，转换为csv文件，再导入Notion也是可行的。不过，我更喜欢用官方原生方法来处理。几经折腾，最终还是找到了最优方法。折腾过程就不多啰嗦了，各种看官时间宝贵，我还是直接说答案吧。

```bash
formatDate(prop("Date"), "W")
```

先来看下`formatDate()`这个公式的官方示例。

```bash
# 语法
formatDate(date, text)
# 示例
formatDate(now(), "MMMM D YYYY, HH:mm") == March 30 2010, 12:00
formatDate(now(), "YYYY/MM/DD, HH:mm") == 2010/03/30, 12:00
formatDate(now(), "MM/DD/YYYY, HH:mm") == 03/30/2010, 12:00
formatDate(now(), "HH:mm A") == 12:00 PM
formatDate(now(), "M/D/YY") == 3/30/10
```

就是用格式化（FORMAT）日期字符串格式化输出日期（date），很多编程语言都有这种用法。

比如shell中Date命令
```bash
$ date +"%Y/%m/%d %H-%M-%S"
2020/03/28 18-51-24
```

python中datetime模块

```bash
>>> a = datetime.datetime.now()
>>> a.strftime("%Y/%m/%d")
'2020/03/28'
```

shell与python中计算当日属于第几周的格式（FORMAT）如下

```bash
%W	一年中的第几周，以周一为每星期第一天(00-53)
%V	ISO-8601 格式规范下的一年中第几周，以周一为每星期第一天(01-53)
%U	一年中的第几周，以周日为每星期第一天(00-53)
```

Notion中对应FORMAT如下。

```bash
# 一年中第几周，以周一(大写W)为每星期第一天（1-53）
formatDate(Date, "W")
# 一年中第几周，以周日（小写w）为每星期第一天（1-53）
formatDate(Date, "w")
```

比如，2019年12月29日是周日，按照第一种方式的话，计算出来就是2019年第52周，用第二种方式计算出来是2020年第1周。显然，第一种方式更符合我们的要求。

趁热打铁，我又试出了其他几个Notion未公布的FORMAT。

```bash
# 毫秒时间戳（x小写）
formatDate(Date, "x")
# 秒时间戳（x大写）
formatDate(Date, "X")
# 时区（CST），z小写
formatDate(Date, "z")
# 时区（+08:00），z大写
formatDate(Date, "z")
# 长格式时间（3/28/2020），l小写
formatDate(Date, "l")
# 长格式时间（03/28/2020），L大写
formatDate(Date, "L")
# 周几（周日的话输出0，其它为1-6），e小写
formatDate(Date, "e")
# 周几（周日的话输出7，其它为1-6），e大写
formatDate(Date, "E")
```

## 后记

极限测试发现该方法有问题：2000年12月31日是星期日，该日应属于当年第53周，不过上述公式计算出来的结果是：第52周。2000年1月1日属于第一周，上述计算出来的结果是：第52周。

所以，各位如果有计算某日属于第几周的需求可以用我这个公式，虽然复杂了点（使用公式前把"Date"字段替换为要计算周数的日期字段）。

```bash
if(day(dateAdd(fromTimestamp(-115200000), year(prop("Date")) - year(fromTimestamp(-115200000)), "years")) != 0 and ceil(dateBetween(prop("Date"), dateSubtract(dateAdd(fromTimestamp(-115200000), year(prop("Date")) - year(fromTimestamp(-115200000)) - 1, "years"), day(dateAdd(fromTimestamp(-115200000), year(prop("Date")) - year(fromTimestamp(-115200000)) - 1, "years")), "days"), "days") / 7) == 53, 1, ceil(dateBetween(prop("Date"), dateSubtract(dateAdd(fromTimestamp(-115200000), year(prop("Date")) - year(fromTimestamp(-115200000)) - 1, "years"), day(dateAdd(fromTimestamp(-115200000), year(prop("Date")) - year(fromTimestamp(-115200000)) - 1, "years")), "days"), "days") / 7))
```

## 参考

- [2020年习惯打卡原版](https://www.notion.so/Habit-tracker-9bba62739d744103a1e7c4000d4b4251)
- [2020年习惯打卡中文版](https://www.notion.so/cnotion/2020-8fa0b3f42d2742c38440b3549de99b5b)
