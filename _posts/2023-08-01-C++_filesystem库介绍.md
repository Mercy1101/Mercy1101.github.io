---
title: "C++ filesystem 库介绍"
toc: true
show_date: true
toc_sticky: true
author_profile: true
---

`std::filesystem` 是 C++17 中引入的标准库，用于处理文件系统操作。它提供了一组类和函数，用于执行文件和目录的创建、删除、遍历、重命名、复制等操作，以及获取文件和目录的属性信息。

## std::filesystem::path 核心概念解释

`std::filesystem::path` 类用于表示文件系统路径。它提供了一组函数，用于获取路径的各个部分，以及将路径转换为字符串。

该对象把 `linux` 与 `windows` 中的路径进行统一的封装，规避掉了不同系统下的路径分隔符不同的问题。

该对象可以方便的通过 `std::string` 进行构造，可以方便的转换为 `std::string`。

```cpp
#include <iostream>
#include <filesystem>

int main()
{
    std::filesystem::path p1("C:\\Windows\\System32\\drivers\\etc\\hosts");
    std::filesystem::path p2("C:/Windows/System32/drivers/etc/hosts");
    std::filesystem::path p3("C:", std::filesystem::path::format::generic_format);
    std::filesystem::path p4("Windows/System32/drivers/etc/hosts", std::filesystem::path::format::generic_format);
    std::filesystem::path p5("hosts", std::filesystem::path::format::generic_format);
    std::filesystem::path p6("C:\\Windows\\System32\\drivers\\etc\\hosts", std::filesystem::path::format::native_format);
    std::filesystem::path p7("C:/Windows/System32/drivers/etc/hosts", std::filesystem::path::format::native_format);
    std::filesystem::path p8("C:", std::filesystem::path::format::native_format);
    std::filesystem::path p9("Windows/System32/drivers/etc/hosts", std::filesystem::path::format::native_format);
    std::filesystem::path p10("hosts", std::filesystem::path::format::native_format);

    std::cout << p1 << std::endl;
    std::cout << p2 << std::endl;
    std::cout << p3 << std::endl;
    std::cout << p4 << std::endl;
    std::cout << p5 << std::endl;
    std::cout << p6 << std::endl;
    std::cout << p7 << std::endl;
    std::cout << p8 << std::endl;
    std::cout << p9 << std::endl;
    std::cout << p10 << std::endl;

    std::cout << p1.string() << std::endl;
    std::cout << p2.string() << std::endl;
    std::cout << p3.string() << std::endl;
    std::cout << p4.string() << std::endl;
    std::cout << p5.string() << std::endl;
    std::cout << p6.string() << std::endl;
    std::cout << p7.string() << std::endl;
    std::cout << p8.string() << std::endl;
    std::cout << p9.string() << std::endl;
    std::cout << p10.string() << std::endl;

    return 0;
}
```

## 使用场景

### 获取当前路径

```cpp
#include <iostream>
#include <filesystem>

int main()
{
    std::filesystem::path p = std::filesystem::current_path();
    std::cout << p << std::endl;

    auto str = p.str();
    std::cout << str << std::endl;
    return 0;
}
```

### 获取绝对路径

```cpp
#include <iostream>
#include <filesystem>

int main()
{
    std::filesystem::path p = std::filesystem::absolute("hosts");
    std::cout << p << std::endl;

    auto str = p.str();
    std::cout << str << std::endl;
    return 0;
}
```

### 判断文件或文件夹是否存在

```cpp
#include <iostream>
#include <filesystem>

int main()
{
    std::filesystem::path p("hosts");
    if (std::filesystem::exists(p))
    {
        std::cout << "exists" << std::endl;
    }
    else
    {
        std::cout << "not exists" << std::endl;
    }
    return 0;
}
```

### 创建文件夹

```cpp
#include <iostream>
#include <filesystem>

int main()
{
    std::filesystem::path p("test");
    /// 递归创建文件夹
    if (std::filesystem::create_directories(p))
    {
        std::cout << "create directory success" << std::endl;
    }
    else
    {
        std::cout << "create directory failed" << std::endl;
    }
    return 0;
}
```

> `std::filesystem::create_directory` 与 `std::filesystem::create_directories` 的区别
> `std::filesystem::create_directory` 用于创建单个目录，如果目录已经存在，则函数会抛出 `std::filesystem::filesystem_error` 异常。
> `std::filesystem::create_directories` 用于创建多级目录，如果目录已经存在，则函数不会抛出异常。
> 因此，如果你需要创建多级目录，可以使用 `std::filesystem::create_directories`，如果你只需要创建单个目录，则可以使用 `std::filesystem::create_directory`。

### 创建文件

```cpp
#include <iostream>
#include <filesystem>

int main()
{
    std::filesystem::path p("test.txt");
    if (std::filesystem::create_directory(p))
    {
        std::cout << "create file success" << std::endl;
    }
    else
    {
        std::cout << "create file failed" << std::endl;
    }
    return 0;
}
```


### 获取当前磁盘容量

```cpp
#include <iostream>
#include <filesystem>

int main()
{
    std::filesystem::path p("C:");
    std::filesystem::space_info info = std::filesystem::space(p);
    std::cout << "capacity: " << info.capacity << std::endl;
    std::cout << "free: " << info.free << std::endl;
    std::cout << "available: " << info.available << std::endl;
    return 0;
}
```

### 获取文件大小

```cpp
#include <iostream>
#include <filesystem>

int main()
{
    std::filesystem::path p("hosts");
    std::cout << "file size: " << std::filesystem::file_size(p) << std::endl;
    return 0;
}
```

### 获取文件夹下所有文件

```cpp
#include <iostream>
#include <vector>
#include <regex>
#include <string>
#include <filesystem>

std::vector<std::string> get_directory_files(const std::string& path, const std::regex& reg, bool is_recursive)
{
    auto p = std::filesystem::path(path);
    if (!is_exist(p.string()))
    {
        return {};
    }

    std::vector<std::string> vec;
    auto f = [&](const auto& dir_entry)
    {
        auto fp = dir_entry.path();
        /// 过滤文件夹
        if (!std::filesystem::is_directory(std::filesystem::status(fp)))
        {
            auto file_name = fp.filename().string();
            /// 正则匹配
            if (std::regex_match(file_name, reg))
            {
                vec.push_back(fp.string());
            }
        }
    };

    if (is_recursive)
    {
        /// 递归查找
        std::ranges::for_each(std::filesystem::recursive_directory_iterator{p}, f);
    }
    else
    {
        /// 非递归查找
        std::ranges::for_each(std::filesystem::directory_iterator{p}, f);
    }

    std::ranges::sort(vec);
    return vec;
}

int main()
{

    /// 默认情况下，查找所有文件, 非递归
    auto c0 = get_directory_files(dir1.string());
    /// 非递归，查找所有文件
    auto c1 = get_directory_files(dir1.string(), std::regex("(.*)"), false);
    /// 非递归，查找特定文件 .log
    auto c2 = get_directory_files(dir1.string(), std::regex("(.*\\.log)"), false);
    /// 递归，查找所有文件
    auto c3 = get_directory_files(dir1.string(), std::regex("(.*)"), true);
    /// 递归，查找特定文件 .log
    auto c4 = get_directory_files(dir1.string(), std::regex("(.*\\.log)"), true);

    return 0;

}

```

### 文件重命名

```cpp
#include <iostream>
#include <filesystem>

int main()
{
    std::filesystem::path p("hosts");
    std::filesystem::path new_p("hosts_new");
    std::filesystem::rename(p, new_p);
    return 0;
}
```

### 移动文件

```cpp
#include <iostream>
#include <filesystem>

int main()
{
    std::filesystem::path p("hosts_new_copy");
    std::filesystem::path new_p("hosts_new_copy_move");
    std::filesystem::rename(p, new_p);
    return 0;
}
```

### 拷贝文件

```cpp
#include <iostream>
#include <filesystem>

int main()
{
    std::filesystem::path p("hosts_new");
    std::filesystem::path new_p("hosts_new_copy");
    std::filesystem::copy(p, new_p);
    return 0;
}
```

### 拷贝文件夹

```cpp
bool copy_directory(const std::string& from, const std::string& to) noexcept
{
    if (!std::filesystem::is_directory(from))
    {
        return false;
    }

    if (!is_exist(from))
    {
        return false;
    }

    if (is_exist(to))
    {
        return false;
    }
    /// 文件存在的情况下则更新，文件递归拷贝
    const auto copy_options = std::filesystem::copy_options::update_existing | std::filesystem::copy_options::recursive;

    std::error_code code;
    std::filesystem::copy(from, to, copy_options, code);
    return !code;
}
```