---
layout: post
title:  "C++ nullptr与NULL"
date:   2020-12-15 18:58:39 +0800
categories: c++
published:  true
tag: c++
typora-root-url: ..
---

# NULL与nullptr的区别
NULL为宏定义
```c++
#define NULL 0
```

NULL的类型不明显，而一下情况会出现函数重载不明确的情况
```c++
void f1(int i){}
void f1(int* p){}

int main(){
  f1(NULL); ///< 调用函数不确定，编译器警告或报错
}
```
而`nullptr`是一个特殊类型(`nullptr_t`)专门用来指代空指针。见下面代码
```c++
void f1(int i){}  ///< #1
void f1(int* p){} ///< #2

int main(){
  f1(nullptr); ///< 明确调用#2函数
}
```