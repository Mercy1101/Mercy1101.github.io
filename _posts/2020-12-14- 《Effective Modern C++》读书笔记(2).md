﻿---
title:  "《Effective Modern C++》读书笔记(2)"
toc: true
toc_sticky: true
---

# 《Effective Modern C++》读书笔记(2)

1. 裸指针在声明中并没有指出，裸指针指涉到的是单个对象还是一个数组。

2. 裸指针在声明中也没有提示在使用完指涉到的对象以后，是否需要析构它。换言之，你从声明中看不出来指针是否拥有其指涉的对象。
3. 即使知道需要析构指针所指涉的对象，也不可能知道如何析构才是适当的。是应该使用`delete`运算符，还是有其他用途。
4. 即使知道了使用`delete`运算符，还是会发生到底应该用的那个对象形式（`delete`）还是数组形式（`delete[]`）。
5. 即启用够确信，指针拥有其指涉对象，并且也确知应该如何析构，要保证析构在所有代码路径上都仅执行一次（包括那些异常导致的路径）仍然困难重重。只要少在一条路径上执行，就会导致资源泄露。而如果析构在一条路径上执行了多次，则会导致未定义行为。
6. 没有什么正规的方式能检测出指针是否空悬，也就是说，它指涉的内存是否已经不再持有指针本应该指涉的对象。如果一个对象已经被析构了，而某些指针仍然指涉到它，就会产生空悬指针。

在创建对象时注意区分`()`和`{}`

```c++
Widget w1;  ///< 调用默认构造函数
Widget w2 = w1; ///< 调用复制构造函数
w1 = w2;  ///< 赋值运算符
```

大括号可以用来为非静态成员指定默认初始化值，却不能使用小括号。
```c++
class Widget {
private:
int x{0}; ///< 可行
int y = 0;  ///< 可行
int z(0); ///< 不可行
};
```

不可复制的对象可以采用大括号和小括号来进行初始化，却不能使用`=`:
```c++
std::atomic<int> ai1{0}; ///< 可行
std::atomic<int> ai2(0); ///< 可行
std::atomic<int> ai3 = 0; ///< 不可行
```
大括号适用所有场合。
大括号初始化有一项新特性，就是它禁止内建型别之间进行隐式窄化型别转换。而采用小括号和`=`的初始化则不会进行窄化型别转换检查，因为如果那样的化就会破坏太多的遗留代码了。

大括号初始化的另一项值得一提的特征是，它对于C++最令人苦恼之解析语法免疫。C++规定：任何能够解析为声明的都要解析为声明。本来想要以默认方式构造一个对象，结果却一不小心声明了一个函数。这个错误的根本原因构造函数调用语法。
当你想要以传参的方式调用构造函数时：
```c++
Widget w1(10);  ///< 调用Widget的构造函数，传入形参10
```
但你如果试图用相同的语法构造一个没有形参的Widget的话，结果却变成了声明了一个函数而非对象：
```c++
Widget w2();  ///< 最令人苦恼之解析语法现身
```
由于函数声明不能使用大括号来指定形参列表，所以使用大括号来完成对象的默认构造上面这个问题：
```c++
Widget w3{};  ///< 调用没有形参的Widget构造函数
```

大括号初始化的缺陷在于伴随它有时会出现的意外行为。这种行为源于大括号初始化物、`std::initializer_list`以及构造函数重载决议之间的纠结。

如果一个或多个构造函数声明了任何一个具备`std::initializer_list`型别的形参那么采用了大括号初始化语法的调用语句会强烈地优先选用带有`std::initializer_list`型别形参的重载版本。
```c++
class Widget {
  public:
  Widget(int i, bool b);
  Widget(int i, double d);
  Widget(std::initializer_list<long double> il);
};

Widget w1(10, true);  ///< 调用第一个构造函数
Widget w2{10, true};  ///< 使用最后一个构造函数, 10, true 被强制转化为long double

```

如果你的确想要调用一个带有`std::initializer_list`型别形参的构造函数，并传入一个空的`std::initializer_list`的话，你可以通过把空大括号对作为构造函数实参的方式实现这个目的，即把一对空大括号放入一对小括号或大括号的方式来清楚地表明你传递地是什么：
```c++
Widget w4({});  ///< 带有std::initializer_list型别形参地构造函数
Widget w5{{}};  ///< 同上
```

```c++
std::vector<int> v1(10, 20);  ///< 创建了一个拥有十个元素，每个元素值都为20的vector
std::vector<int> v1(10, 20);  ///< 创建了一个拥有两个元素，值分别为10、20 的vector
```

`std::make_unique`和`std::make_shared`在函数内部使用的小括号，作为其接口的一部分。

* 大括号初始化可以应用的语境最为宽泛，可以阻止隐式窄化型别转换，还对最令人苦恼之解析语法免疫
* 在构造函数重载决议期间，只要有任何可能，大括号初始化物就会与带有`std::initializer_list`型别的形参相匹配，即使其他重载版本有着貌似更加匹配的形参表。
* 使用小括号还是大括号，会造成结果大相径庭的一个例子是：使用两个实参来创建一个`std::vector<数值型别>`对象。
* 在模板内容进行对象创建时，到底应该使用小括号还是大括号会成为一个棘手问题。

## 理解特种成员函数的生成机制
两种复制操作是彼此独立的：声明了其中一个，并不会阻止编译器生成另外一个。如果你生成了一个复制构造函数，同时未声明复制赋值运算符，并撰写了要求复制赋值的代码，则编译器会为你生成复制赋值运算符。反过来一样。

两种移动操作并不彼此独立：声明了其中一个就会阻止编译器生成另外一个。假设你声明了一个移动构造函数，你实际上表明了移动操作的实现方式将会与编译器生成的默认按成员移动的移动构造函数多少有些不同。而若是按成员进行的移动构造操作有不合用之处的话，那么按成员进行的移动赋值运算符极有可能也会有不合用之处。综上声明一个移动构造函数会阻止编译器去生成移动赋值运算符，而声明一个移动赋值运算符也会阻止编译器去生成移动构造函数。

一旦显式声明了赋值操作，这个类也就不再会生成移动操作了。依据在于，声明复制操作的行为表明了对象的常规复制途径（按成员复制）对于该类并不适用。从而判定既然按成员复制不适用于赋值操作，则按成员移动极有可能也不适用于移动操作。
一旦声明了移动操作，编译器就会删除复制操作。

三大律：如果你声明了复制构造函数、复制复制运算符，或析构函数中的任何一个，你就得同时声明所有这三个。
如果有改写复制操作的需求，往往意味着该类需要执行某种资源管理，而这就意味着：1. 在一种复制操作中进行的任何资源管理，也极有可能在另一种复制操作中也需要进行。 2. 该类的析构函数也会参与到该资源的管理之中。

大三律的一个推论是，如果存在用户声明的析构函数，则平凡的按成员赋值也不适用于该类。如果声明了析构函数，则复制操作就不该被自动生成，因为他们呢的行为不可能正确。所以在C++11中：只要用户声明了析构函数，就不会生成移动操作。

移动操作的生成条件（如果需要生成）仅当以下三者同时成立：
* 该类未声明任何复制操作
* 该类未声明任何移动操作
* 该类未声明任何析构操作

总而言之， C++11中， 支配特种成员函数的机制如下：
* 默认构造函数： 仅当类中不包含用户声明的构造函数时才生成
* 析构函数：与C++98中基本相同，唯一的区别在于析构函数默认为`noexcept`.仅当基类的析构函数为虚的，派生类析构函数才是虚的。
* 复制构造函数： 按成员进行非静态数据成员的复制构造。仅当类中不包含用户声明的复制构造函数时才生成。如果该类声明了移动操作，则复制构造函数将被删除。在已经存在复制赋值运算符或析构函数的条件下，仍然生成复制构造函数已经成为了被废弃的行为。
* 移动构造函数和移动赋值运算符
都按成员进行非静态数据成员的移动操作。仅当类中不包含用户声明的复制操作、移动操作和析构函数时才生成。

成员函数模板的存在会阻止编译器生成任何特种成员函数。

* 移动操作仅当类中未包含用户显式声明的复制操作、移动操作和析构函数时才生成
* 复制构造函数仅当类中不包含用户显式声明的复制构造函数时才生成，如果该类声明了移动操作则复制构造函数时才生成，复制赋值运算符仅当类中不包含用户显式声明的复制赋值运算符才生成，如果该类声明了移动操作则复制赋值运算符将被删除。在已经存在显式声明的析构函数的条件下，生成复制操作已经成为了被废弃的行为。
* 成员函数模板在任何情况下都不会抑制特种成员函数的生成。

* auto 变量必须初始化，基本上对会导致兼容性和效率问题的型别不匹配现象免疫，还可以简化重构流程，通常也比显式指定型别少打一些字

* 在模板推导过程中，具有引用型别的实参会被当成非引用型别来处理。换言之，其引用性会被忽略。
* 对万能引用形参进行推导时，左值实参会进行特殊处理。
* 对按值传递的形参进行推导时，若实参型别中带有`const`或`volatile`饰词，则它们还是会被当作不带`const`或`volatile`饰词的型别来处理。
* 在模板型别推导过程中， 数组或函数型别的实参会退化成对应的指针，除非它们被用来初始化引用。

* 在一般情况下，auto型别推导和模板型推导是一模一样的，但是auto型别推导会假定用大括号括起的初始化表达式代表一个`std::initializer_list`, 但模板型别推导却不会。
* 在函数返回值或lambda式的形参中使用auto， 意思是使用模板型别推导而非auto型推导。

* 绝大多数情况下，`decltype`会得出变量或表达式的型别而不做任何修改
* 对于型别为T的左值表达式，除非该表达式仅有一个名字，`decltype`总是得出型别`T&`
