
[C++ 具名要求：分配器 (Allocator)](https://zh.cppreference.com/w/cpp/named_req/Allocator)
[C++ named requirements: Allocator](https://en.cppreference.com/w/cpp/named_req/Allocator)

```c++
#include <cstdlib>
#include <new>
#include <limits>
#include <iostream>
#include <vector>

template <class T>
struct Mallocator
{
  typedef T value_type;

  Mallocator () = default;
  template <class U> constexpr Mallocator (const Mallocator <U>&) noexcept {}

  [[nodiscard]] T* allocate(std::size_t n) {
    if (n > std::numeric_limits<std::size_t>::max() / sizeof(T))
      throw std::bad_alloc();

    if (auto p = static_cast<T*>(std::malloc(n*sizeof(T)))) {
      report(p, n);
      return p;
    }

    throw std::bad_alloc();
  }

  void deallocate(T* p, std::size_t n) noexcept {
    report(p, n, 0);
    std::free(p);
  }

private:
  void report(T* p, std::size_t n, bool alloc = true) const {
    std::cout << (alloc ? "Alloc: " : "Dealloc: ") << sizeof(T)*n
      << " bytes at " << std::hex << std::showbase
      << reinterpret_cast<void*>(p) << std::dec << '\n';
  }
};

template <class T, class U>
bool operator==(const Mallocator <T>&, const Mallocator <U>&) { return true; }
template <class T, class U>
bool operator!=(const Mallocator <T>&, const Mallocator <U>&) { return false; }

int main()
{
  std::vector<int, Mallocator<int>> v(8);
  v.push_back(42);
}
```

[TinySTL/TinySTL/Allocator.h](https://github.com/zouxiaohang/TinySTL/blob/master/TinySTL/Allocator.h)
```c++
    /*
    **空间配置器，以变量数目为单位分配
    */
    template<class T>
    class allocator{
    public:
        typedef T           value_type;
        typedef T*          pointer;
        typedef const T*    const_pointer;
        typedef T&          reference;
        typedef const T&    const_reference;
        typedef size_t      size_type;
        typedef ptrdiff_t   difference_type;
    public:
        static T *allocate();
        static T *allocate(size_t n);
        static void deallocate(T *ptr);
        static void deallocate(T *ptr, size_t n);

        static void construct(T *ptr);
        static void construct(T *ptr, const T& value);
        static void destroy(T *ptr);
        static void destroy(T *first, T *last);
    };

    template<class T>
    T *allocator<T>::allocate(){
        return static_cast<T *>(alloc::allocate(sizeof(T)));
    }
    template<class T>
    T *allocator<T>::allocate(size_t n){
        if (n == 0) return 0;
        return static_cast<T *>(alloc::allocate(sizeof(T) * n));
    }
    template<class T>
    void allocator<T>::deallocate(T *ptr){
        alloc::deallocate(static_cast<void *>(ptr), sizeof(T));
    }
    template<class T>
    void allocator<T>::deallocate(T *ptr, size_t n){
        if (n == 0) return;
        alloc::deallocate(static_cast<void *>(ptr), sizeof(T)* n);
    }

    template<class T>
    void allocator<T>::construct(T *ptr){
        new(ptr)T();
    }
    template<class T>
    void allocator<T>::construct(T *ptr, const T& value){
        new(ptr)T(value);
    }
    template<class T>
    void allocator<T>::destroy(T *ptr){
        ptr->~T();
    }
    template<class T>
    void allocator<T>::destroy(T *first, T *last){
        for (; first != last; ++first){
            first->~T();
        }
    }
```


```c++
namespace MyLib {
   template <class T>
   class MyAlloc {
     public:
       // type definitions
       typedef T        value_type;
       typedef T*       pointer;
       typedef const T* const_pointer;
       typedef T&       reference;
       typedef const T& const_reference;
       typedef std::size_t    size_type;
       typedef std::ptrdiff_t difference_type;

       // rebind allocator to type U
       template <class U>
       struct rebind {
           typedef MyAlloc<U> other;
       };

       // return address of values
       pointer address (reference value) const {
           return &value;
       }
       const_pointer address (const_reference value) const {
           return &value;
       }

       /* constructors and destructor
        * - nothing to do because the allocator has no state
        */
       MyAlloc() throw() {
       }
       MyAlloc(const MyAlloc&) throw() {
       }
       template <class U>
         MyAlloc (const MyAlloc<U>&) throw() {
       }
       ~MyAlloc() throw() {
       }

       // return maximum number of elements that can be allocated
       size_type max_size () const throw() {
           return std::numeric_limits<std::size_t>::max() / sizeof(T);
       }

       // allocate but don't initialize num elements of type T
       pointer allocate (size_type num, const void* = 0) {
           // print message and allocate memory with global new
           std::cerr << "allocate " << num << " element(s)"
                     << " of size " << sizeof(T) << std::endl;
           pointer ret = (pointer)(::operator new(num*sizeof(T)));
           std::cerr << " allocated at: " << (void*)ret << std::endl;
           return ret;
       }

       // initialize elements of allocated storage p with value value
       void construct (pointer p, const T& value) {
           // initialize memory with placement new
           new((void*)p)T(value);
       }

       // destroy elements of initialized storage p
       void destroy (pointer p) {
           // destroy objects by calling their destructor
           p->~T();
       }

       // deallocate storage p of deleted elements
       void deallocate (pointer p, size_type num) {
           // print message and deallocate memory with global delete
           std::cerr << "deallocate " << num << " element(s)"
                     << " of size " << sizeof(T)
                     << " at: " << (void*)p << std::endl;
           ::operator delete((void*)p);
       }
   };

   // return that all specializations of this allocator are interchangeable
   template <class T1, class T2>
   bool operator== (const MyAlloc<T1>&,
                    const MyAlloc<T2>&) throw() {
       return true;
   }
   template <class T1, class T2>
   bool operator!= (const MyAlloc<T1>&,
                    const MyAlloc<T2>&) throw() {
       return false;
   }
}
```

[SGI-STL/SGI-STL V3.3/alloc.h](https://github.com/steveLauwh/SGI-STL/blob/master/SGI-STL%20V3.3/alloc.h)

[boost default_allocator](https://www.boost.org/doc/libs/1_78_0/libs/core/doc/html/core/default_allocator.html)

[《STL源码剖析》提炼总结：空间配置器(allocator)](https://zhuanlan.zhihu.com/p/34725232)


