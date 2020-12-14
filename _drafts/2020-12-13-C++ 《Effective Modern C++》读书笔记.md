---
layout: post
title:  "《Effective Modern C++》读书笔记"
date:   2020-12-13 10:19:33 +0800
categories: c++ 读书笔记
published:  true
tag: c++ 读书笔记
typora-root-url: ..
---

在运行期， `std::move`和`std::forward`都不会做任何操作。

```c++
void f(Widget&& param); ///< 右值引用
Widget&& var1 = Widget(); ///< 右值引用
auto&& var2 = var1; ///< 非右值引用

template<typename T>
void f(std::vector<T>&& param)  ///< 右值引用

template<typename T>
void f(T&& param) ///< 非右值引用
```

`T&&`有两种不同的含义
1. 右值引用
2. 表示既可以是右值引用也可以是左值引用

万能引用会在两个地方现身
```c++
template<typename T>
void f(T&& param);  ///< param是个万能引用
```
```c++
auto&& var2 = var1; ///< var2是个万能引用
```

而不涉及型别推导`&&`就是右值引用
```c++
void f(Widget&& param); ///< 不涉及型别推导
```
`const`关键字也可以确定`const T&&`是右值引用
```c++
template<typename T>
void f(const T&& param);
```

在一个模板中的`T&&`也不一定是万能引用， 见下面。
```c++
template<class T, class Allocator = allocator<T>>
class vector {
public:
  void push_back(T&& x);
};
```
因为`push_back`是`vector`的成员函数， 如果`vector`实例存在的话就一定有确定的类型，所以并不存在型别推导。

另外，声明`auto&&`都是万能引用。