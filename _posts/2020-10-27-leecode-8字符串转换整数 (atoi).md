---
layout: leetcode
title:  "leetcode 8. 字符串转换整数 (atoi)"
date:   2020-10-27 21:52:52 +0800
categories: c++ leetcode
published:  true
tag: c++ leetcode
typora-root-url: ..
---

8. 字符串转换整数 (atoi)

```c++
class Solution {
public:
    int myAtoi(string str) {
         str.erase(0, str.find_first_not_of(' '));
  if (str.front() == '+') {
    if (std::isdigit(*std::next(str.begin()))) {
      str.erase(str.begin());
    } else {
      return 0;
    }
  }
  int flag = 1;
  if (str.front() == '-') {
    if (!std::isdigit(*std::next(str.begin()))) {
      return 0;
    } else {
      str.erase(str.begin());
      flag = -1;
    }
  }
  auto it_end = str.end();
  for (auto it = str.begin(); it != str.end(); ++it) {
    if (!std::isdigit(*it)) {
      it_end = it;
      break;
    }
  }

  std::string num(str.begin(), it_end);
  if (num.empty()) {
    return 0;
  }
  long long result = 0;
  for (int i = 0; i < num.size(); ++i) {
    result += num.at(i) - '0';

    if (result > INT_MAX && (flag == 1)) {
      return INT_MAX;
    }
    if (result * flag < INT_MIN && (flag == -1)) {
      return INT_MIN;
    }
    if (i == num.size()-1) {
      break;
    }
    result *= 10;
  }
  return static_cast<int>(result * flag);
    }
};
```