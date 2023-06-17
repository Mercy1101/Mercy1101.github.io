---

title:  "阅读spdlog-thread_pool源码"
date:   2020-06-26 09:18:47 +0800
categories: 源码阅读   # 文章的类别
# description: description
published:  true   # default true 设置 “false” 后，文章不会显示
tag: c++
typora-root-url: ..
toc: true
---

## thread_pool 源码学习
### 源码定义
我们先概览一下[spdlog-thread_pool定义](https://github.com/gabime/spdlog/blob/v1.x/include/spdlog/details/thread_pool.h)
```c++
class SPDLOG_API thread_pool
{
public:
    using item_type = async_msg;
    using q_type = details::mpmc_blocking_queue<item_type>;

    thread_pool(size_t q_max_items, size_t threads_n,
                std::function<void()> on_thread_start);
    thread_pool(size_t q_max_items, size_t threads_n);
    ~thread_pool();

    thread_pool(const thread_pool &) = delete;
    thread_pool &operator=(thread_pool &&) = delete;

    void post_log(async_logger_ptr &&worker_ptr, const details::log_msg &msg,
                  async_overflow_policy overflow_policy);
    void post_flush(async_logger_ptr &&worker_ptr,
                    async_overflow_policy overflow_policy);
    size_t overrun_counter();

private:
    q_type q_; ///< 任务队列
    std::vector<std::thread> threads_;  ///< 线程池

    void post_async_msg_(async_msg &&new_msg,
                         async_overflow_policy overflow_policy);
    void worker_loop_();
    bool process_next_msg_();
};
```

### 基本成员函数
首先我们从thread_pll中最基本的五个成员函数开始看。
```c++
    thread_pool(size_t q_max_items, size_t threads_n,
                std::function<void()> on_thread_start);
    thread_pool(size_t q_max_items, size_t threads_n);

    // message all threads to terminate gracefully join them
    ~thread_pool();

    thread_pool(const thread_pool &) = delete;
    thread_pool &operator=(thread_pool &&) = delete;
```

可以看到该类删除了拷贝构造，移动构造，标志该类不可以被拷贝和移动。
其中有两个构造函数，我们来详细看看它们的实现。
```c++
  /// @name     thread_pool
  /// @brief    构造函数，创建了一定数量的线程，并规定执行哪个函数
  ///
  /// @param    q_max_item      [in] 用于初始化任务队列最大的数量
  /// @param    thread_n        [in] 用于初始化最大线程数量
  /// @param    on_thread_start [in] 每个线程执行的初始化函数(只执行一次)
  ///
  /// @return   NONE
  ///
  /// @date     2020-06-27 13:32:47
  inline thread_pool(size_t q_max_items, size_t threads_n,
                     std::function<void()> on_thread_start)
      : q_(q_max_items) ///< 任务队列的最大数目
  {
    if (threads_n == 0 || threads_n > 1000) {
      throw(
          "spdlog::thread_pool(): invalid threads_n param (valid "
          "range is 1-1000)");
    }
    for (size_t i = 0; i < threads_n; i++) {
      threads_.emplace_back([this, on_thread_start] {
        /// 线程开始时候需要执行的初始函数
        on_thread_start();
        /// 主任务循环
        this->thread_pool::worker_loop_();
      });
    }
  }

  /// 委托构造函数，用于输入默认入参 std::function<void()>
  inline thread_pool::thread_pool(size_t q_max_items, size_t threads_n)
      : thread_pool(q_max_items, threads_n, [] {}) {}
```

接着我们来看一下析构函数执行了什么
```c++
  /// 告诉所有线程中止，并且执行join()
  ~thread_pool() {
    try {
      for (size_t i = 0; i < threads_.size(); i++) {
        /// 对每一个线程池发送一个中止消息
        post_async_msg_(async_msg(async_msg_type::terminate),
                        async_overflow_policy::block);
      }

      for (auto &t : threads_) {
        /// 等待每一个线程的结束时的join
        t.join();
      }
    } catch (...) {
      /// 析构函数中不能有异常，所以在这里做一个全捕获
    }
  }
```
### 生产者逻辑
接着我们来看公有的两个接口函数的实现
```c++
  /// 用于发送任务消息，并判断是否需要打印到命令行或写入文件
  void post_log(async_logger_ptr &&worker_ptr, const log_msg &msg,
                async_overflow_policy overflow_policy) {
    async_msg async_m(std::move(worker_ptr), async_msg_type::log, msg);
    post_async_msg_(std::move(async_m), overflow_policy);
  }

  /// 用于发送任务消息，并判断是否需要马上写入文件
  void post_flush(async_logger_ptr &&worker_ptr,
                  async_overflow_policy overflow_policy) {
    post_async_msg_(async_msg(std::move(worker_ptr), async_msg_type::flush),
                    overflow_policy);
  }

  /// 用于返回任务队列溢出了多少条
  size_t overrun_counter() { return q_.overrun_counter(); }
```

 `post_log` 和 `post_flush` 执行了一个差不多的任务，就是写日志，这两个函数都调用了`post_async_msg_()`来执行具体的任务们就来看看`post_async_msg_()`到底执行了什么。

 ```c++
  /// @name     post_async_msg_
  /// @brief    用于从队列中插入消息, 相当于生产者
  ///
  /// @param    new_msg         [in] 用于传入异步日志消息(使用右值方便移动)
  /// @param    overflow_policy [in] 消息数量溢出的策略
  ///
  /// @return   NONE
  ///
  /// @date     2020-06-27 13:42:18
  void post_async_msg_(async_msg &&new_msg,
                       async_overflow_policy overflow_policy) {
    if (overflow_policy == async_overflow_policy::block) {
      /// 阻塞至消息队列中有空间来插入消息
      q_.enqueue(std::move(new_msg));
    } else {
      /// 立即插入队列且队列满时丢弃老的消息
      q_.enqueue_nowait(std::move(new_msg));
    }
  }
 ```
### 消费者逻辑
 如上面的实现，我们知道这是一个生产者，从外部插入到本对象内的任务队列，等待消费者来处理这些消息
 我们来看看消费者到底执行了什么。
```c++
  /// @name     worker_loop_
  /// @brief    用于每个线程执行的死循环，当process_next_msg_返回false时候
  ///           线程自己退出
  ///
  /// @param    NONE
  ///
  /// @return   NONE
  ///
  /// @date     2020-06-27 13:51:13
  void worker_loop_() {
    /// 如果处理消息没有返回false，就一致执行该函数
    while (process_next_msg_()) {
    }
  }

  /// @name     process_next_msg_
  /// @brief    处理队列中的下一个消息，相当于消费者
  ///
  /// @param    NONE
  ///
  /// @return   如果不是中止线程消息，则返回true, 反之返回false
  ///
  /// @date     2020-06-27 13:53:45
  bool process_next_msg_() {
    async_msg incoming_async_msg;
    /// 从任务消息队列中取消息，如果没有任务则等待获取任务,
    /// 如十秒后仍然没有获取到则直接返回
    bool dequeued =
        q_.dequeue_for(incoming_async_msg, std::chrono::seconds(10));
    /// 如果获取任务消息失败则直接返回true
    if (!dequeued) {
      return true;
    }

    /// 获取到消息后则进行处理
    switch (incoming_async_msg.msg_type) {
      case async_msg_type::log: {
        /// 打印消息到命令行且判断是否要马上刷新文件
        incoming_async_msg.worker_ptr->backend_sink_it_(incoming_async_msg);
        return true;
      }
      case async_msg_type::flush: {
        /// 刷新文件
        incoming_async_msg.worker_ptr->backend_flush_();
        return true;
      }

      case async_msg_type::terminate: {
        /// 用于终止本线程池的信号
        return false;
      }

      default: {
        assert(false);
      }
    }
    return true;
  }
```
上面代码的逻辑我们可以看到：首先由`worker_loop()`函数来不停的执行消费者函数。
而消费者函数在不停地去任务队列中获取任务最后由`backend_sink_it_()` 和 `backend_flush_()`两个函数来执行真正地任务。

### 任务队列
很简单的一个消费者和生产者的队列，但最核心的部分被一个任务队列`mpmc_blocking_queue<async_msg>`给封装了，让我们继续深入来看看这个任务队列。
```c++
template <typename T>
class mpmc_blocking_queue {
 public:
  using item_type = T;
  explicit mpmc_blocking_queue(size_t max_items) : q_(max_items) {}

  /// 尝试入列，如果空间不足则阻塞
  void enqueue(T &&item) {
    {
      std::unique_lock<std::mutex> lock(queue_mutex_);
      pop_cv_.wait(lock, [this] { return !this->q_.full(); });
      q_.push_back(std::move(item));
    }
    push_cv_.notify_one();
  }

  /// 马上入列，如果没有空间则丢弃队列中老的消息
  void enqueue_nowait(T &&item) {
    {
      std::unique_lock<std::mutex> lock(queue_mutex_);
      q_.push_back(std::move(item));
    }
    push_cv_.notify_one();
  }

  /// 尝试出列。如果队列中没有消息，则等待到超时然后再次尝试
  /// 假如出列成功则返回true, 否则返回false
  bool dequeue_for(T &popped_item, std::chrono::milliseconds wait_duration) {
    {
      std::unique_lock<std::mutex> lock(queue_mutex_);
      if (!push_cv_.wait_for(lock, wait_duration,
                             [this] { return !this->q_.empty(); })) {
        return false;
      }
      popped_item = std::move(q_.front());
      q_.pop_front();
    }
    pop_cv_.notify_one();
    return true;
  }

  size_t overrun_counter() {
    std::unique_lock<std::mutex> lock(queue_mutex_);
    return q_.overrun_counter();
  }

 private:
  std::mutex queue_mutex_;           ///< 用于控制整个对象的锁
  std::condition_variable push_cv_;  ///< 用于入列的条件变量
  std::condition_variable pop_cv_;   ///< 用于出列的条件变量
  circular_q<T> q_;                  ///< 用于保存信息的队列
};
```
我们来看看这个队列是怎么实现线程安全的。
其中`q_`这个循环队列不是线程安全的，所以加上了一个`queue_mutex` 这个互斥锁用来同步所有成员函数的顺序并配合条件变量实现等待获取的功能。


`spdlog-thread_pool` 的实现逻辑很清晰，我们可以对比一下Github上另一个thread-pool: [progschj/ThreadPool](https://github.com/progschj/ThreadPool/blob/master/ThreadPool.h) 的实现。
由于需要写入的任务很明确，就是处理异步日志，所以任务的队列直接写死了处理异步日志消息。而progschj/ThreadPool的实现则更加灵活。我们可以看看我的另一篇博客[阅读progschj/thread_pool源码](./_site/源码阅读/2020/06/27/阅读线程池源码.html)对progschj/ThreadPool的介绍