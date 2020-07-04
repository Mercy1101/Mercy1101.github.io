---
layout: post
title:  "C++容器特性与适用场景"
date:   2020-07-03 21:12:05 +0800
categories: c++   
published:  true
tag: c++
typora-root-url: ..
---

# C++容器的特性与适用场景
## 容器类别


首先放上一张来自《C++标准库》中的图片。
![STL Container Types](/resource/容器特性与适用场景/STL_Container_Types.png)

### 1. 序列式容器（Sequence container）

这是一种有序(ordered)集合，其内每个元素均有确凿的位置----取决于插入时机和地点，与元素值无关。如果你以追加方式对一个集和置入6个元素，他们的排列次序将和置入次序一致。STL提供了5个定义好的序列式容器：array、vector、deque、list和forward_list。

### 2. 关联式容器(Associative container)

这是一种已排序(sorted)集合，元素位置取决于其value(或key----如果元素是个key/value pair)和给定的某个排序准则。如果将六个元素置入这样的集合中，他们的值将决定他们的次序，和插入次序无关。STL提供了4个关联式容器：set、multiset、map和multimap。

### 3. 无序容器（Unordered (associative) container）

这是一种无序集合(unordered collection), 其内每个元素的每个位置无关紧要，唯一重要的是某特定元素是否位于此集合内。元素值或其安插顺序，都不影响元素的位置，而且元素的位置有可能在容器生命周期中被改变。如果你放6个元素到这种集合内，它们的次序不明确，并且可能随时间而改变。STL内含4个预定义的无序容器：unordered_set、unordered_multiset、unordered_map和unordered_multimap。

+ **Sequence**容器通常被实现为array或linked list

+ **Associative**容器通常被实现为binary tree

+ **Unordered**容器通常被实现为hash table

### 各种容器使用时机

  ![ContainerSelect](/resource/容器特性与适用场景/ContainerSelect.png)

+ 默认情况下应该使用`std::vector`。`std::vector`的内部构造最简单，并允许随机访问，所以数据的访问十分方便灵活，数据的处理也够快。

+ 如果经常要在**序列头部和尾部安插和一处元素**，应该采用`std::deque`。如果你希望元素被移除时，容器能够自动缩减内部用量，那么也该使用`std::deque`。此外，由于`std::vector`通常采用一个内存区块来存放元素，而`std::deque`采用**多个区块**，所以后者可内含更多元素。

+ 如果需要经常**在容器中段执行元素安插、移除和移动**，可考虑使用`std::list`。`std::list`提供特殊的成员函数，可在**常量时间内将元素从A容器转移到B容器**。但由于`std::list`**不支持随机访问**，所以如果只知道list的头部却要造访list的中端元素，效能会大打折扣。和所有“以节点为基础”的容器相似，**只要元素仍是容器的一部分，list就不会令指向那些元素的迭代器失效**。`std::vector`则不然，一旦超过其容量，它的所有`iterator`、`pointer`和`reference`失效。至于`std::deque`，当它的大小改变，所有`iterator`、`pointer`和`reference`都会失效。

+ 如果你要的容器对异常处理使得“**每次操作若不成功便无任何作用**”，那么应该选用`std::list`(但是不调用其assignment操作符和sort(), 而且如果元素比较过程中会抛出异常，就不要调用merge()、remove()、remove_if()和unique()，或选用associative/unordered容器（但不调用多元素安插动作，而且**如果比较准则的复制/赋值动作可能抛出异常，就不要调用swap()或erase()**）)。

+ 如果你经常需要根据某个准则**查找元素**，应当使用“依据该准则进行hash”的`std::unordered_set` 或`std::multiset`。然而，hash容器内是无序的，所以如果你必须以来元素的次序(order),应该使用`std::set`或`std::multiset`，他们根据查找准则对元素排序。

+ 如果想处理key/value pair，请采用`unordered_map`或`std::unordered_multimap`。如果元素次序很重要，可采用`std::map`或`std::multimap`。

+ 如果需要关联式数组(associative array), 应采用unordered map。如果元素次序很重要，可采用map。

+ 如果需要字典结构，应采用unordered multimap。如果元素次序很重要，可采用multimap。

![ContainerTypes](/resource/容器特性与适用场景/ContainerTypes.png)

这里应该有一个表格来翻译上面的图片
||Array|Vector|Dequeue|List|Forward List|关联容器|无序容器|
|-|-|-|-|-|-|-|-|
|