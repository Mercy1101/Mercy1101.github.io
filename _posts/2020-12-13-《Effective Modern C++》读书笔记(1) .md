---
layout: post
title:  "《Effective Modern C++》读书笔记(1)"
date:   2020-12-13 10:19:33 +0800
categories: c++ 读书笔记
published:  true
tag: c++ 读书笔记
typora-root-url: ..
---

# 《Effective Modern C++》读书笔记(1) 
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

针对右值引用实施`std::move`，针对万能引用实施`std::forward`

当转发右值引用给其他函数是，应当对其实施向右值的无条件强制型别转换(通过`std::move`)，因为它们一定绑定到右值，而当转发万能引用时，应当对其实施向右值的有条件强制型别转换(通过`std::forward`), 因为它们不一定绑定到右值。
应当避免针对右值引用实施`std::forward`。而另一方面，针对万能引用使用`std::move`的想法更为糟糕，因为那样做的后果是某些左值会遭到意外改动(例如某些临时变量)。

```c++
class Widget {
public:
  template<typename T>
  void setName(T&& newName) {
    name = std::move(newName);  ///< 可以编译但糟糕透顶
  }
private:
  std::string name;
  std::shared_ptr<SomeDataStructure> p;
};

std::string getWidgetName();  ///< 工厂函数

Widget w;

auto n = getWidgetName(); ///< n是个局部变量

w.setName(n); ///< 将n移入了w

... ///< n的值变得未知了
```

```c++
Widget makeWidget() {
  Widget w;
  ... ///< 对w进行操作
  return w; ///< 没有任何东西被复制
}

Widget makeWidget() {
  Widget w;
  ...
  return std::move(w);  ///< 将w移入返回值, 千万不要这么做
}
```

`RVO`(return value optimization): 编译器若要在一个按值返回的函数里省略对局部对象的复制（或者移动）, 则需要满足两个前提条件： 1. 局部对象型别和函数返回值型别相同. 2. 返回的就是局部对象本身。即使实施`RVO`的前提条件满足，但编译器选择不执行复制省略的时候，返回对象必须作为右值处理。当`RVO`的前提条件允许时，要么发生复制省略，要么`std::move`隐式地被实施于返回的局部对象。

* 针对右值引用的最后一次使用实施`std::move`, 针对万能引用的最后一次使用实施`std::forward`。
* 作为按值返回的函数的右值引用和万能引用，依上一条所述采取相同行动。
* 若局部对象可能适用于返回值优化，则请勿针对其实施`std::move`或`std::forward`

```c++
template<typename T>
void logAndAdd(T&& name) {
  logAndAddImpl(std::forward<T>(name), std::is_integral<T>());  ///< std::is_integral不够正确
}
```
`std::is_integral<>`不够正确是因为如果传给万能引用`name`实参是个左值，那么`T`就会被推导为左值引用。因为`int&`不是`int`.

```c++
template<typename T>
void logAndAdd(T&& name) {
  logAndAddImpl(std::forward<T>(name), std::is_integral<std::remove_reference_t<T>>());
}
```

完美转发的含义是我们不仅转发对象，还转发其显著特征：型别、左值还是右值，以及是否带有`const`和`volation`饰词等等。

大括号初始化物
假设`f`的声明如下：
```c++
void f(const std:vector<int>& v);
```
在此情况下，以大括号初始化物调用`f`可以通过编译：
```c++
f({1,2,3})
```
但如果把同一大括号初始化物的运用，就是一种完美转发失败的情形。编译器采用推导的手法来取得传递给`fwd`实参的型别结果，尔后它会比较推导型别结果和`f`声明的形参型别。完美转发会在下面两个条件中的任何一个成立时失败：
* 编译器无法为一个或多个`fwd`的形参推导出型别结果。编译器无法编译通过。
* 编译器为一个或多个`fwd`的形参推导出了"错误的"型别结果。

```c++
template<typename... Ts>
void fwd(Ts&&... params){
  f(std::forward<Ts>(params)...);
}

class Widget{
  public:
  static const std::size_t MinVals = 28;
}
```

```c++
f(Widget::MinVals); ///< 没问题, 当f(28)处理
fwd(Widget::MinVals); ///< 错误，无法链接
```
无法链接的原因是，完美转发，转发的是入参(`Widget::MinVals`)的引用，而引用在编译器底层是指针实现的。由于`static`变量并没有被分配实际的地址，所以产生了链接错误。

完美转发的失败情形还包括：重载的函数名字和模板名字。
```c++
void f(int (*pf)(int)); ///< 一个接受函数指针入参的函数f
int processVal(int value);
int processVal(int value, int priority);

/// 然后调用
f(processVal);
```
上面在调用函数`f`的时候，其中`processVal`仅仅只是函数的名字，但编译器知道匹配的是单入参版本的函数。

而使用完美转发时，编译器是无法知道使用的是什么版本。
```c++
fwd(processVal);  ///< 编译不过
```

最后一种完美转发失败的情形是位域被用作函数实参的时候。
标准中：非`const`引用不得绑定到位域。既然没有办法创建指涉到任意比特的指针(C++标准规定，可以指涉的最小实体是单个char)，那自然没有办法把引用绑定到任意比特上了。
```c++
struct IPV4Header {
  std::uint32_t version:4,
  IHL:4,
  DSCP:6,
  ECN:2,
  totalLength:16;
};

f(h.totalLength); ///< 没问题
fwd(h.totalLength); ///< 错误！
```
把位域传递给完美转发函数的关键，就是利用转发目的函数接收的总是位域值的副本这一事实。可以自己复制一份，并以该副本调用。
```c++
auto length = static_cast<std::uint16_t>(h.totalLength);
fwd(length);
```

