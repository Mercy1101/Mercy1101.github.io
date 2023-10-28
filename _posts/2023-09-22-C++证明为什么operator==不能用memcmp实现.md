---
title: "C++证明为什么operator==不能用memcmp实现"
toc: true
show_date: true
toc_sticky: true
author_profile: true
---

问： 结构体重载 `operator==` 能否直接使用 `memcmp` 实现？

```c++
struct obj
{
    /// 这样实现是否正确
    bool operator==(const obj& other) const
    {
        return memcmp(this, &other, sizeof(other)) == 0;
    }

    ...
};
```

先说结论：不可以。

理由为：

1. 非 `POD` 类型的结构体，拥有容器类型的成员中可能存在动态内存，其地址肯定不一样，但内容可能一样，因此不能直接使用 `memcmp` 来比较。
2. `POD` 类型，数组中没有被赋值的垃圾值，会影响内存比较结果。如果保存了指针又想要比较指针指向的内容是否一致，则也不能直接使用 `memcmp` 来比较。

见如下代码：

```c++
#include <iostream>
#include <cassert>

struct obj
{
    bool operator==(const obj& other) const
    {
        return memcmp(this, &other, sizeof(other)) == 0;
    }

    unsigned ulUserID;
    char acName[32];
    unsigned ulDCType;
};

int main()
{
    obj st;
    obj st1;

    assert(st == st1);  ///< 无法通过

    st.ulUserID = 1;
    st.ulDCType = 1;
    st.acName[0] = 'a';
    st1.ulUserID = 1;
    st1.ulDCType = 1;
    st1.acName[0] = 'a';
    assert(st == st1);  ///< 无法通过

    return 0;
}
```

解决办法：

C++11 以前：

```c++
struct obj
{
    bool operator==(const obj& other) const
    {
        return ulUserID == other.ulUserID
            && ulDCType == other.ulDCType
            && strcmp(acName, other.acName, sizeof(acName)) == 0;
    }

    unsigned ulUserID;
    char acName[32];
    unsigned ulDCType;
};
```

C++11 以后 C++20 以前：

```c++
struct obj
{
    bool operator==(const obj& other) const = default;

    unsigned ulUserID;
    char acName[32];
    unsigned ulDCType;
};
```

C++20 以后：

```c++
struct obj
{
    auto operator<=>(const obj&) const = default;

    unsigned ulUserID;
    char acName[32];
    unsigned ulDCType;
};