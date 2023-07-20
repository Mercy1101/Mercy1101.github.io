---

title:  "C++ integer_sequence介绍"
date:   2020-07-22 19:30:09 +0800
categories: c++
published:  true
tag: c++
typora-root-url: ..
toc: true
toc_sticky: true
---

## integer_sequence
```c++
#include <array>
#include <iostream>
#include <tuple>
#include <utility>

template <typename T, T... ints>
void print_sequence(std::integer_sequence<T, ints...> int_seq) {
  std::cout << "" << int_seq.size() << ": ";
  ((std::cout << ints << ' '), ...);
  std::cout << '\n';
}

/// 转化数组为tuple
template <typename Array, std::size_t... I>
auto a2t_impl(const Array& a, std::index_sequence<I...>) {
  return std::make_tuple(a[I]...);
}

template <typename T, std::size_t N,
          typename Indices = std::make_index_sequence<N>>
auto a2t(const std::array<T, N>& a) {
  return a2t_impl(a, Indices{});
}

/// 漂亮地打印 tuple
template <class Ch, class Tr, class Tuple, std::size_t... Is>
void print_tuple_impl(std::basic_ostream<Ch, Tr>& os, const Tuple& t,
                      std::index_sequence<Is...>) {
  ((os << (Is == 0 ? "" : ", ") << std::get<Is>(t)), ...);
}

template <class Ch, class Tr, class... Args>
auto& operator<<(std::basic_ostream<Ch, Tr>& os, const std::tuple<Args...>& t) {
  os << "(";
  print_tuple_impl(os, t, std::index_sequence_for<Args...>{});
  return os << ")";
}

int main() {
  print_sequence(std::integer_sequence<unsigned, 9, 2, 5, 1, 9, 1, 6>{});
  print_sequence(std::make_integer_sequence<int, 20>{});
  print_sequence(std::make_index_sequence<10>{});
  print_sequence(std::index_sequence_for<float, std::iostream, char>{});

  std::array<int, 4> array = {1, 6, 3, 4};

  auto tuple = a2t(array);
  static_assert(std::is_same<decltype(tuple), std::tuple<int, int, int, int>>::value, "");

  std::cout << tuple <<'\n';
  system("pause");
}
```
