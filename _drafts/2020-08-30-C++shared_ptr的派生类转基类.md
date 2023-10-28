
```c++
#include <algorithm>
#include <functional>
#include <iostream>
#include <memory>
#include <vector>

class A {
 public:
  virtual void out() { std::cout << "A" << std::endl; }
};

class B : public A, public std::enable_shared_from_this<B> {
 public:
  std::shared_ptr<B> getCallback() { return shared_from_this(); }
  void out() override { std::cout << "B" << std::endl; }
};

class X {
 public:
  std::shared_ptr<A> x;
  void set(std::shared_ptr<A> set) { x = set; }
  void xx() { x->out(); }
};

int main() {
  auto b = std::make_shared<B>();
  X x;
  x.set(b->getCallback());
  x.xx();

  system("pause");
}
```