---
layout: post
title:  "阅读spdlog-rotating_file_sink源码"
date:   2020-07-04 21:39:47 +0800
categories: 源码阅读 
published:  true
tag: c++
typora-root-url: ..
---

# thread_pool 源码学习
## rotating_file_sink定义
[rotating_file_sink.h](https://github.com/gabime/spdlog/blob/v1.x/include/spdlog/sinks/rotating_file_sink.h)

```C++
//
// Rotating file sink based on size
//
template<typename Mutex>
class rotating_file_sink final : public base_sink<Mutex>
{
public:
    rotating_file_sink(filename_t base_filename, std::size_t max_size, std::size_t max_files, bool rotate_on_open = false);
    static filename_t calc_filename(const filename_t &filename, std::size_t index);
    filename_t filename();

protected:
    void sink_it_(const details::log_msg &msg) override;
    void flush_() override;

private:
    // Rotate files:
    // log.txt -> log.1.txt
    // log.1.txt -> log.2.txt
    // log.2.txt -> log.3.txt
    // log.3.txt -> delete
    void rotate_();

    // delete the target if exists, and rename the src file  to target
    // return true on success, false otherwise.
    bool rename_file_(const filename_t &src_filename, const filename_t &target_filename);

    filename_t base_filename_;          ///< 基础文件名称
    std::size_t max_size_;              ///< 最大单个文件大小
    std::size_t max_files_;             ///< 最大日志文件数量
    std::size_t current_size_;          ///< 当前文件的大小
    details::file_helper file_helper_;  ///< 用于辅助写文件的对象
};
```

### 构造函数
```C++

/// @name     rotating_file_sink
/// @brief    构造本对象，
///           1. 打开日志文件
///           2. 获取当前文件大小
///           3. 如果超出了单个文件大小，则重新创建文件并打开
///
/// @param    base_filename   [in]  基础的文件名
/// @param    max_size        [in]  最大单个文件大小
/// @param    max_files       [in]  最大的文件
/// @param    rotate_on_open  [in]  是否在文件打开时rotate
///
/// @date     2020-07-04 21:51:27
rotating_file_sink(std::string base_filename, std::size_t max_size,
                   std::size_t max_files, bool rotate_on_open = false)
    : base_filename_(std::move(base_filename)),
      max_size_(max_size),
      max_files_(max_files) {
  /// 打开当前应该写入的文件，并由file_helper对象来持有这个文件指针
  file_helper_.open(calc_filename(base_filename_, 0));
  /// 该函数时间执行时间很长，在这里只执行一次。
  current_size_ = file_helper_.size();
  /// 假如允许rotate且当前文件大小大于零
  if (rotate_on_open && current_size_ > 0) {
    /// 执行一次rotate
    rotate_();
  }
}
```

### rotate_()函数
```C++
  /// @name     rotate_
  /// @brief    执行循环日志文件的创建
  /// @details  
  /// Rotate files:
  /// log.txt -> log.1.txt
  /// log.1.txt -> log.2.txt
  /// log.2.txt -> log.3.txt
  /// log.3.txt -> delete
  ///
  /// @param    NONE
  ///
  /// @return   NONE
  ///
  /// @date     2020-07-04 21:58:24
  inline void rotate_() {
    /// 首先关闭该文件
    file_helper_.close();
    /// 开始查找要创建的下一个日志文件名称
    for (auto i = max_files_; i > 0; --i) {
      /// 拼装出上一个该文件名称
      std::string src = calc_filename(base_filename_, i - 1);
      if (!path_exists(src)) {
        /// 该文件如果不存在则到下一个循环
        continue;
      }
      /// 这里找到要创建的日志名称了日志文件的名称
      std::string target = calc_filename(base_filename_, i);

      /// 把上一个文件改名为当前的文件名
      if (!rename_file_(src, target)) {
        /// 如果失败则在一个短暂的延迟后再次尝试
        sleep_for_millis(100);
        if (!rename_file_(src, target)) {
          /// 关闭并打开这个日志文件，防止它增长超出限制
          file_helper_.reopen(true);
          current_size_ = 0;
          /// 抛出异常
          throw("rotating_file_sink: failed renaming ");
        }
      }
    }
    /// 以追加模式("a")重新打开这个文件
    file_helper_.reopen(true);
  }
```

### calc_filename()
