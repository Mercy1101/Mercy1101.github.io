

* 使用`_beginthreadex`创建多个线程，无法使用`WaitForMultipleObjects`来进行同步。


从文件 `C:\Program Files (x86)\Windows Kits\10\Source\10.0.10240.0\ucrt\startup\thread.cpp` 中查看代码

```c++
extern "C" uintptr_t __cdecl _beginthreadex(
    void*                    const security_descriptor,
    unsigned int             const stack_size,
    _beginthreadex_proc_type const procedure,
    void*                    const context,
    unsigned int             const creation_flags,
    unsigned int*            const thread_id_result
    )
{
    _VALIDATE_RETURN(procedure != nullptr, EINVAL, 0);

    unique_thread_parameter parameter(create_thread_parameter(procedure, context));
    if (!parameter)
    {
        return 0;
    }

    DWORD thread_id;
    HANDLE const thread_handle = CreateThread(
        reinterpret_cast<LPSECURITY_ATTRIBUTES>(security_descriptor),
        stack_size,
        thread_start<_beginthreadex_proc_type>,
        parameter.get(),
        creation_flags,
        &thread_id);

    if (!thread_handle)
    {
        __acrt_errno_map_os_error(GetLastError());
        return 0;
    }

    if (thread_id_result)
    {
        *thread_id_result = thread_id;
    }

    // If we successfully created the thread, the thread now owns its parameter:
    parameter.detach();

    return reinterpret_cast<uintptr_t>(thread_handle);
}
```

```c++
template <typename ThreadProcedure>
static unsigned long WINAPI thread_start(void* const parameter) throw()
{
    if (!parameter)
    {
        ExitThread(GetLastError());
    }

    __acrt_thread_parameter* const context = static_cast<__acrt_thread_parameter*>(parameter);

    __acrt_getptd()->_beginthread_context = context;

    if (__acrt_is_packaged_app())
    {
        context->_initialized_apartment = __acrt_RoInitialize(RO_INIT_MULTITHREADED) == S_OK;
    }

    __try
    {
        ThreadProcedure const procedure = reinterpret_cast<ThreadProcedure>(context->_procedure);

        _endthreadex(invoke_thread_procedure(procedure, context->_context));
    }
    __except (_seh_filter_exe(GetExceptionCode(), GetExceptionInformation()))
    {
        // Execution should never reach here:
        _exit(GetExceptionCode());
    }

    // This return statement will never be reached.  All execution paths result
    // in the thread or process exiting.
    return 0;
}
```

```c++
static __acrt_thread_parameter* __cdecl create_thread_parameter(
    void* const procedure,
    void* const context
    ) throw()
{
    unique_thread_parameter parameter(_calloc_crt_t(__acrt_thread_parameter, 1).detach());
    if (!parameter)
    {
        return nullptr;
    }

    parameter.get()->_procedure = procedure;
    parameter.get()->_context   = context;

    // Attempt to bump the reference count of the module in which the user's
    // thread procedure is defined, to ensure that the module will stay loaded
    // as long as the thread is executing.  We will release this HMDOULE when
    // the thread procedure returns or _endthreadex is called.
    GetModuleHandleExW(
        GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS,
        reinterpret_cast<LPCWSTR>(procedure),
        &parameter.get()->_module_handle);

    return parameter.detach();
}
```

```c++
static void __cdecl common_end_thread(unsigned int const return_code) throw()
{
    __acrt_ptd* const ptd = __acrt_getptd_noexit();
    if (!ptd)
    {
        ExitThread(return_code);
    }

    __acrt_thread_parameter* const parameter = ptd->_beginthread_context;
    if (!parameter)
    {
        ExitThread(return_code);
    }

    if (parameter->_initialized_apartment)
    {
        __acrt_RoUninitialize();
    }

    if (parameter->_thread_handle != INVALID_HANDLE_VALUE && parameter->_thread_handle != nullptr)
    {
        CloseHandle(parameter->_thread_handle);
    }

    if (parameter->_module_handle != INVALID_HANDLE_VALUE && parameter->_module_handle != nullptr)
    {
        FreeLibraryAndExitThread(parameter->_module_handle, return_code);
    }
    else
    {
        ExitThread(return_code);
    }
}

extern "C" void __cdecl _endthread()
{
    return common_end_thread(0);
}

extern "C" void __cdecl _endthreadex(unsigned int const return_code)
{
    return common_end_thread(return_code);
}
```


[CreateThread 和 _beginthreadex 区别](https://www.cnblogs.com/lgxqf/archive/2009/02/10/1387480.html)

C++ 运行库里面有一些函数使用了全局
量，如果使用 CreateThread 的情况下使用这些C++ 运行库的函数，就会出现不安全
的问题。而 _beginthreadex 为这些全局变量做了处理，使得每个线程都有一份独立
的“全局”量。

_beginthreadex是一个C运行时库的函数，CreateThread是一个系统API函 数，_beginthreadex内部调用了CreateThread。只所以所有的书都强调内存泄漏的问题是因为_beginthreadex函数在创 建线程的时候分配了一个堆结构并和线程本身关联起来，我们把这个结构叫做tiddata结构，是通过线程本地存储器TLS于线程本身关联起来。我们传入的 线程入口函数就保存在这个结构中。tiddata的作用除了保存线程函数入口地址之外，还有一个重要的作用就是:C运行时库中有些函数需要通过这个结构来 保存和获取一些数据，比如说errno之类的线程全局变量。这点才是最重要的。

绝对不要调用系统自带的CreateThread函数创建新的线程，而应该使用_beginthreadex，除非你在线程中绝不使用需要tiddata结构的运行时库函数

”如果在除主线程之外的任何线程中进行一下操作，你就应该使用多线程版本的C runtime library,并使用_beginthreadex和_endthreadex：

1 使用malloc()和free()，或是new和delete

2 使用stdio.h或io.h里面声明的任何函数

3 使用浮点变量或浮点运算函数

4 调用任何一个使用了静态缓冲区的runtime函数，比如:asctime(),strtok()或rand()


[_beginthreadex和CreateThread的区别和联系](https://blog.csdn.net/shines/article/details/7055510)
在 Win32 API 中，创建线程的基本函数是 CreateThread，而 _beginthread(ex) 是C++ 运行库的函数。为什么要有两个呢？因为C++ 运行库里面有一些函数使用了全局量，如果使用 CreateThread 的情况下使用这些C++ 运行库的函数，就会出现不安全的问题。而 _beginthreadex 为这些全局变量做了处理，使得每个线程都有一份独立的“全局”量。

所以，如果你的编程只调用 Win32 API/SDK ，就放心用 CreateThread；如果要用到C++ 运行时间库，那么就要使用 _beginthreadex ，并且需要在编译环境中选择 Use MultiThread Lib/DLL。

[_beginthreadex和CreateThread](http://blog.chinaunix.net/uid-17102734-id-2830124.html)
_beginthreadex在内部调用了CreateThread，在调用之前_beginthreadex做了很多的工作，从而使得它比CreateThread更安全。

```c++
BOOL fFailure = (system("NOTEPAD.EXE README.TXT") == -1);

if (fFailure) {
     switch (errno) {
     case E2BIG: // Argument list or environment too big
         break;

   case ENOENT: // Command interpreter cannot be found
       break;

   case ENOEXEC: // Command interpreter has bad format
       break;

   case ENOMEM: // Insufficient memory to run command
       break;
   }
}
```

设想这样的情况，当上面的代码执行到system函数之后，if声明之前的时候，操作系统打断了它，而转去执行进程中的另一个线程，而这个线程正好使用了会设置errno的某个CRT函数... 问题出现了。
为了解决这个问题，每个线程需要自己的errno全局变量，而且还需要一些机制来使得它们使用它们自己的errno变量，而不是其他线程的。

其他使用全局变量的还有：_doserrno, strtok, _wcstok, strerror, _strerror, tmpnam, tmpfile, asctime, _wasctime, gmtime, _ecvt, _fcvt

为了让C和C++程序能够正常工作，必须创建一个数据结构，并把它与每一个线程关连起来，只有这样才能调用CRT库时不至于误入“其他线程家园”。

那么系统怎么知道在创建一个新线程时分配这个数据块呢？回答是系统不知道，这一切责任都在你，只有你才能确保所有的事情正常完成。只需要调用_beginthreadex函数

_beginthreadex函数只存在于CRT库的多线程版本中，如果你链接到了一个单线程运行时库，链接器会毫不客气地报告 “unresolved external symbol”错误。另外，还需要注意的是VS在创建新项目时默认选择的是单线程库，所以需要记得修改设置。