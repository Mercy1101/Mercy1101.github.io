# 常用 Window API 简介

## [PostMessageA function (winuser.h)](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-postmessagea)

放置一个特定窗口创建的线程关联的消息到消息队列，然后不等待直接从发送消息的线程中退出。
使用 `PostThreadMessage` 让一个线程发送一个消息到消息队列中。

```c++
BOOL PostMessageA(
  [in, optional] HWND   hWnd,
  [in]           UINT   Msg,
  [in]           WPARAM wParam,
  [in]           LPARAM lParam
);
```

### 参数

#### [in, optional] hWnd

一个接收消息到窗口过程的句柄

| Value                         | 意义                                                                               |
| ----------------------------- | ---------------------------------------------------------------------------------- |
| HWND_BROADCAST ((HWND)0xffff) | 这个消息被发送到系统中所有顶层窗口, 包括失能、非自己所有、重叠和弹出的窗口         |
| NULL                          | 这个函数表现为使用 `dwThreadId` 参数设置为标志符为当前线程调用 `PostThreadMessage` |

#### [in] Msg

将要被发送的消息。关于系统提供的消息见， [System-Defined Messages](https://docs.microsoft.com/en-us/windows/win32/winmsg/about-messages-and-message-queues)

#### [in] wParam

额外的消息特定的信息

#### [in] lParam

额外的消息特定的信息

### 返回值

假如函数成功返回非零值。
假如函数失败返回零。获取扩展的错误信息，调用 [GetLastError](https://docs.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror)


## [PostMessageA function (winuser.h)](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-postthreadmessagea)

发送一个消息到一个特定线程的消息队列。它返回立即返回，不会等待线程处理消息

```c++
BOOL PostThreadMessageA(
  [in] DWORD  idThread,
  [in] UINT   Msg,
  [in] WPARAM wParam,
  [in] LPARAM lParam
);
```


### 参数

#### [in] idThread

消息将要被发送到的线程的标识符

假如特定的线程不含有消息队列则函数将会失败。系统在线程第一次调用 `User` 或 `GDI` 函数时创建一个线程消息队列。 更多信息见 Remark 章节。

消息发送是一个到 `UIPI` 的对象。 一个进程的线程可以发送消息 只有进程中的线程发送消息队列小于或等于集成的层级。

这个线程必须有`SE_TCB_NAME`优先级去发送一个消息到属于一个有相同本地唯一id(LUID)但在不同桌面的进程的线程， 否则函数执行失败并返回 `ERROR_INVALID_THREAD_ID`

#### [in] Msg

将要被发送的消息类型。

#### [in] wParam

附加的特定消息信息。

#### [in] lParam

附加的特定消息信息

### 返回值

假如函数成功，返回值为非零值。

假如函数失败，返回值为零。

调用 [GetLastError](https://docs.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror) 获取详细信息。

假如 `idThread` 不是一个有效的 `id` 或者线程没有消息队列, `GetLastError` 返回 `ERROR_INVALID_THREAD_ID`

假如消息到达上限则 `GetLastError` 返回 `ERROR_NOT_ENOUGH_QUOTA `.

### 附注

当消息被 `UIPI` 最后一个错误阻塞，调用 `GetLastError` 来回复。

接收消息的线程必须有消息队列，否则调用 `PostThreadMessage` 失败。使用以下方法来处理这种情况：

* 创建一个时间对象然后创建线程
* 在调用 `PostThreadMessage`, 使用 [WaitForSingleObject](https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitforsingleobject)函数去等待事件被设置为信号检测的状态。
* 在被发送的消息的线程中，调用[PeekMessage](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-peekmessagea)来强制系统创建消息队列。
  * `PeekMessage(&msg, NULL, WM_USER, WM_USER, PM_NOREMOVE)`
* 设置事件去标志线程已经准备好接收发送的消息

消息已经发送的消息被调用 `GetMessage` 或 `PeekMessage` 函数已经接收。 `hwnd` 成员返回的 [MSG](https://docs.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-msg) 结构体是 `NULL`。

被 `PostThreadMessage ` 发送的消息与窗口没有关联。通常情况下，消息跟窗口没有关联则不会被 [DispatchMessage](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-dispatchmessage) 函数调度。因此假如一个在模态的循环中的接收线程(就像使用 [MessageBox](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-messagebox) 或 [DialogBox](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-dialogboxa)), 消息将会丢失。为了拦截在模态循环中的消息，使用一个线程特定的 hook.

每个消息队列最多拥有10000个发送的消息。


## [gethostname function (winsock.h)](https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-gethostname)

`gethostname` 函数检索本地电脑的标准 host 名称

```c++
int gethostname(
  [out] char *name,
  [in]  int  namelen
);
```

### 参数

#### [out] name

一个指向接收本地主机名称的缓冲区的指针

#### [in] namelen

`name` 的长度

## 返回值

假如没有错误发生， `gethostname` 返回零。 否则返回 SOCKET_ERROR，通过调用 [`WSAGetLastError`](https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-wsagetlasterror) 来获取具体的[错误码](https://docs.microsoft.com/en-us/windows/win32/winsock/windows-sockets-error-codes-2)

| 错误码              | 意义                                                                                                       |
| ------------------- | ---------------------------------------------------------------------------------------------------------- |
| `WSAEFAULT`         | `name` 入参是空指针或是一个用户地址空间有效的一部分。这个返回值也特指 `namelen` 用来保存完整的主机名称太小 |
| `WSANOTINITIALISED` | `WSAStartup` 要在本函数之前成功调用                                                                        |
| `WSAENETDOWN`       | 网络子系统错误                                                                                             |
| `WSAEINPROGRESS`    | 一个阻塞式 Windows Sockets 1.1 在程序中已经被调用，或者服务提供者仍在回调函数过程中                        |


## [ShowWindow function (winuser.h)](https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow)

设置窗口为特定的显示状态

```c++
BOOL ShowWindow(
  [in] HWND hWnd,
  [in] int  nCmdShow
);
```

### 参数

#### [in] hWnd

Type: HWND

窗口句柄

#### [in] nCmdShow

Type: int

控制窗口如何被显示。假如程序启动的应用提供了 [`STARTUPINFO`](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/ns-processthreadsapi-startupinfoa) 结构体，这个参数会在第一次调用 `ShowWindow` 是被忽略。否则，第一次调用 `ShowWindow` 函数时, 该参数值应从 [WinMain](https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-winmain) 函数中获取的 `CmdShow` 参数。随后的调用参数一个是下面的值:

| 参数                          | 意义                                                                                                                                                                                                                                                                                                                     |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| SW_HIDE                       | 隐藏窗口并激活另一个窗口                                                                                                                                                                                                                                                                                                 |
| SW_SHOWNORMAL、SW_NORMAL      | 激活和显示一个窗口。假如拆给你扣是最大或或最小化的，系统霍夫器原有大小和位置。应用应该在第一次显示窗口时指定该标志                                                                                                                                                                                                       |
| SW_SHOWMINIMIZED              | 激活该窗口，显示为一个最小化的窗口                                                                                                                                                                                                                                                                                       |
| SW_SHOWMAXIMIZED、SW_MAXIMIZE | 激活该窗口，显示为一个最小化的窗口                                                                                                                                                                                                                                                                                       |
| SW_SHOWNOACTIVATE             | 用最近使用的大小和位置，显示一个窗口。这个参数值类似于 `SW_SHOWNORMAL` 只是该窗口没有被激活                                                                                                                                                                                                                              |
| SW_SHOW                       | 在当前的位置和大小，激活并显示该窗口                                                                                                                                                                                                                                                                                     |
| SW_MINIMIZE                   | 最小化特定该窗口然后激活在 Z 方向上的次顶层窗口                                                                                                                                                                                                                                                                          |
| SW_SHOWMINNOACTIVE            | 以最小化的方式显示该窗口。这个参数值除了窗口没有被激活，其他与 `SW_SHOWMINIMIZED` 类似                                                                                                                                                                                                                                   |
| SW_SHOWNA                     | 在当前的大小和位置显示窗口，这个至于 `SW_SHOW` 类似除了窗口没有被激活                                                                                                                                                                                                                                                    |
| SW_RESTORE                    | 激活并显示该窗口. 假如窗口是最小化或最大或，系统恢复其原始的大小和位置。一个应用应该在回复最小化窗口前指定该参数                                                                                                                                                                                                         |
| SW_SHOWDEFAULT                | 设置显示该窗口的显示状态为程序在启动时调用 [`CreateProcess`](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessa) 函数传递的 [`STARTUPINFO`](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/ns-processthreadsapi-startupinfoa) 结构体所指定的 |
| SW_FORCEMINIMIZE              | 最小化一个窗口，虽然这个线程拥有的窗口没有响应。 这个标志位应该仅仅被用来最小化其他线程的窗口                                                                                                                                                                                                                            |

## [GetTickCount function (sysinfoapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-gettickcount)

检测自系统启动以来经过的毫秒数，最多 `49.7` 天。

```c++
DWORD GetTickCount();
```

## [GetSystemTimeAdjustment function (sysinfoapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getsystemtimeadjustment)

确定系统是否对其时钟应用定期时间调整，并获取任何此类调整的值和周期。

```c++
BOOL GetSystemTimeAdjustment(
  [out] PDWORD lpTimeAdjustment,
  [out] PDWORD lpTimeIncrement,
  [out] PBOOL  lpTimeAdjustmentDisabled
);
```

### 参数

### `[out] lpTimeAdjustment`

[out] lpTimeAdjustment

A pointer to a variable that the function sets to the number of lpTimeIncrement 100-nanosecond units added to the time-of-day clock for every period of time which actually passes as counted by the system. This value only has meaning if lpTimeAdjustmentDisabled is FALSE.

[out] lpTimeIncrement

A pointer to a variable that the function sets to the interval in 100-nanosecond units at which the system will add lpTimeAdjustment to the time-of-day clock. This value only has meaning if lpTimeAdjustmentDisabled is FALSE.

[out] lpTimeAdjustmentDisabled

A pointer to a variable that the function sets to indicate whether periodic time adjustment is in effect.

A value of TRUE indicates that periodic time adjustment is disabled, and the system time-of-day clock advances at the normal rate. In this mode, the system may adjust the time of day using its own internal time synchronization mechanisms. These internal time synchronization mechanisms may cause the time-of-day clock to change during the normal course of the system operation, which can include noticeable jumps in time as deemed necessary by the system.

A value of FALSE indicates that periodic time adjustment is being used to adjust the time-of-day clock. For each lpTimeIncrement period of time that actually passes, lpTimeAdjustment will be added to the time of day. If the lpTimeAdjustment value is smaller than lpTimeIncrement, the system time-of-day clock will advance at a rate slower than normal. If the lpTimeAdjustment value is larger than lpTimeIncrement, the time-of-day clock will advance at a rate faster than normal. If lpTimeAdjustment equals lpTimeIncrement, the time-of-day clock will advance at its normal speed. The lpTimeAdjustment value can be set by calling SetSystemTimeAdjustment. The lpTimeIncrement value is fixed by the system upon start, and does not change during system operation. In this mode, the system will not interfere with the time adjustment scheme, and will not attempt to synchronize time of day on its own via other techniques.

### 返回值

如果函数成功返回值为非零，否则为零。
调用函数 [`GetLastError`](https://docs.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror) 获取详细的错误信息。

## [GetLocalTime function (sysinfoapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getlocaltime)

## [GetTickCount64 function (sysinfoapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-gettickcount64)

## [QueryPerformanceCounter function (profileapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/profileapi/nf-profileapi-queryperformancecounter)

检索性能计数器的周期。这个周期时固定在系统 boot 里，而且所有的处理器的周期都是一致。因此这个周期需要也只能在应用初始化之后查询，而且结果可以被缓存。

```c++
BOOL QueryPerformanceFrequency(
  [out] LARGE_INTEGER *lpFrequency
);
```

### 参数

#### [out] lpFrequency

一个指向检索出当前性能计数器周期的变量，每秒的计数。假如安装的硬件不支持高分辨率的性能计数器，这个变量将会被置为零(这种情况不会出现在 Windows XP 或更新的操作系统上)


## [CreateThread function (processthreadsapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createthread)

创建一个线程， 在虚拟地址中调用进程

```c++
HANDLE CreateThread(
  [in, optional]  LPSECURITY_ATTRIBUTES   lpThreadAttributes,
  [in]            SIZE_T                  dwStackSize,
  [in]            LPTHREAD_START_ROUTINE  lpStartAddress,
  [in, optional]  __drv_aliasesMem LPVOID lpParameter,
  [in]            DWORD                   dwCreationFlags,
  [out, optional] LPDWORD                 lpThreadId
);
```

### 参数

#### [in, optional] lpThreadAttributes

一个指向结构体[SECURITY_ATTRIBUTES](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/legacy/aa379560(v=vs.85))的结构体指针,用于确定返回的句柄可以被子进程继承。
假如 `lpThreadAttributes` 为 `NULL`, 句柄不可被继承。

`lpSecurityDescriptor` 成员是结构体的一部分。指定了新线程的安全描述符，如果该指针为 NULL， 则该描述符为默认即来自创建者主句柄。

#### [in] dwStackSize

初始时栈的大小。系统将四舍五入到最近的界面，假如这个值为0，新线程使用默认的大小来执行。更多信息见[Thread Stack Size](https://docs.microsoft.com/en-us/windows/win32/procthread/thread-stack-size)

#### [in] lpStartAddress

一个指针指向应用定义的将要被线程执行的函数。这个指针提供了线程的开始地址。更多信息见[ThreadProc](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/legacy/ms686736(v=vs.85))

#### [in, optional] lpParameter

一个指向变量的指针，该指针将被传递给线程。

#### [in] dwCreationFlags

控制创建的线程的标志。

|值|意义|
|-|-|
|0|线程将在运行后马上运行|
|CREATE_SUSPENDED 0x00000004|线程被挂起的状态下被创建， 在函数 `ResumeThread` 被调用之前不会运行|
|STACK_SIZE_PARAM_IS_A_RESERVATION 0x00010000|`dwStackSize` 变量被指定初始栈的大小，假如标志位没有被指定，`dwStackSize` 将会指定提交的大小|

#### [out, optional] lpThreadId

一个指针指向的变量用于接收线程的标识符，假如这个指针为 `NULL`, 线程的标识符将不会返回。

### 返回值

假如线程创建成功，返回值将是新线程的句柄。
假如线程创建失败，返回值将为 `NULL`. 查看更多详细信息错误信息，调用 [GetLastError](https://docs.microsoft.com/en-us/windows/desktop/api/errhandlingapi/nf-errhandlingapi-getlasterror)

注意: 在 `lpStartAddress` 指向的数据，代码或不可访问的情况下, `CreateThread` 函数仍有可能成功.假如线程运行时开始地址是无效的， 一个异常出现，而且线程终止。由于无效起始地址的线程终止被视为线程的错误推出。
 此行为类似于 CreateProcess 的异步性质，即使进程引用无效或丢失的动态链接库 (DLL)，也会创建该进程。

### 附注

一个进程可以创建的线程数量被可用虚拟内存限制。默认情况下，每个线程在栈空间中拥有一兆字节(1MB), 因此你可以最多创建 2048 个线程。假如你减少默认栈的大小，你可以创建更多的线程。但是，如果您为每个处理器创建一个线程并构建应用程序维护上下文信息的请求队列，您的应用程序将具有更好的性能。一个线程将会在在前一个处理请求前的一个队列中处理所有请求。

新线程的句柄是以 `THREAD_ALL_ACCESS` 权限创建的。假如线程被创建时，一个安全描述符不提供。一个默认的安全描述符将会为新线程使用创建者的主 token 创建。当调用者尝试使用 OpenThread 函数访问线程时，调用者的有效令牌将根据此安全描述符进行评估，以授予或拒绝访问。

新创建的线程在调用 `GetCurrentThread` 函数时对自己拥有全部的权限。

如果线程是在可运行状态下创建的（即，如果未使用CREATE_SUSPENDED标志），则线程可以在CreateThread返回之前开始运行，特别是在调用者收到创建线程的句柄和标识符之前。

线程执行从lpStartAddress参数指定的函数开始。如果此函数返回，则DWORD返回值用于在对 ExitThread函数的隐式调用中终止线程。使用 GetExitCodeThread函数获取线程的返回值。

该线程是使用THREAD_PRIORITY_NORMAL的线程优先级创建的。使用 GetThreadPriority和 SetThreadPriority函数来获取和设置线程的优先级值。

当一个线程终止时，线程对象达到一个信号状态，满足任何在该对象上等待的线程。

线程对象保留在系统中，直到线程终止并且所有句柄都已通过调用 CloseHandle关闭。

ExitProcess、 ExitThread、 CreateThread、 CreateRemoteThread函数和正在启动的 进程（作为 CreateProcess调用的结果）在进程内相互序列化。一次只能在地址空间中发生这些事件中的一个。这意味着存在以下限制：

* 在进程启动和 DLL 初始化例程期间，可以创建新线程，但它们不会开始执行，直到为进程完成 DLL 初始化。
* 一个进程中一次只能有一个线程处于 DLL 初始化或分离例程中。
* 直到它们的 DLL 初始化或分离例程中没有线程时， ExitProcess才会完成。

调用 C 运行时库 (CRT) 的可执行文件中的线程应使用_beginthreadex和_endthreadex函数进行线程管理，而不是 CreateThread和 ExitThread；这需要使用 CRT 的多线程版本。如果使用CreateThread创建的线程调用 CRT，CRT 可能会在内存不足的情况下终止进程。

## [ExitThread function (processthreadsapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-exitthread)

停止正在调用该函数的线程

```c++
void ExitThread(
  [in] DWORD dwExitCode
);
```

### 参数

### [in] dwExitCode

线程的退出码

### 附注

`ExitThread` 是一种C代码的退出存在的线程的首选方式。但是在C++代码中线程在任何析构函数或任何自动清空之前退出。因此在C++代码中你应该从你的线程函数中退出。

当这个函数被调用时（显式调用或从线程过程返回），当前线程的堆栈被释放，线程发起的所有挂起的 I/O 被取消，线程终止。 调用所有附加的动态链接库 (DLL) 的入口点函数，其值指示线程正在与 DLL 分离。

假如当该函数被调用时，该线程是进程中的最后一个线程，这个线程的进程同样终止。

线程的状态变为终止时，释放任何其他线程将会等待该线程终止。线程的终止状态变化从 `STILL_ACTIVE` 变化为 `dwExitCode`的数值

终止一个线程不一定需要从操作系统删除线程对象。一个线程对象将在线程最后一个指向线程的的 `Handle` 被关闭。

函数 `ExitProcess`, `ExitThread`, `CreateThread`, `CreateRemoteThread`, 和一个线程正在启动(作为 `CreateProcess` 调用的结果)在一个线程中是被序列化调用的。在一个内存地址同一时间只有一个这样的事件可以发生。这意味着存在以下限制。
* 在线程启动和 DLL 初始化过程中，新县城可以被创建但是知道 DLL 初始化过程结束才会开始执行。
* 进程中的一个线程一次只能处于 DLL 初始化或分离例程中。
* `ExitProcess` 直到没有线程在 DLL 初始化或分离的例程中前不会返回。

链接到静态 C 运行时库 (CRT) 的可执行文件中的线程应使用 `_beginthread` 和 `_endthread` 进行线程管理，而不是使用 `CreateThread` 和 `ExitThread`。不这样做会导致当调用 `ExitThread` 是有一个小的内存泄漏的结果。另一个变通的方法是是让可执行文件链接动态 CRT DLL。注意这里的内存泄漏只发生在一个 DLL 连接在静态 CRT 且一个线程调用 `DisableThreadLibraryCalls`函数。否则，从链接到静态 CRT 的 DLL 中的线程调用 CreateThread 和 ExitThread 是安全的。

使用 `GetExitCodeThread` 函数接收线程的退出码。

[例子](https://docs.microsoft.com/en-us/windows/win32/sync/using-event-objects)

## [GetExitCodeThread function (processthreadsapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getexitcodethread)

接收一个特定的线程的终止状态。

```c++
BOOL GetExitCodeThread(
  [in]  HANDLE  hThread,
  [out] LPDWORD lpExitCode
);
```

### 参数

#### [in] hThread

一个线程的句柄。

这个句柄必须有 `THREAD_QUERY_INFORMATION` 或 `THREAD_QUERY_LIMITED_INFORMATION` 接入权限。更多信息见 [Thread Security and Access Rights](https://docs.microsoft.com/en-us/windows/win32/procthread/thread-security-and-access-rights)

#### [out] lpExitCode

一个指向接收线程终止状态的线程， 更多详细信息见附注

### 返回值

假如函数执行后成功，返回非零值。
假如函数执行失败，返回值为零，更多错误信息通过调用 `GetLastError` 函数获取。

### 附注

这个函数回立即返回。假如入参的线程没有终止，而且该函数执行成功，将返回状态 `STILL_ACTIVE`. 假如线程终止且函数执行成功，状态返回以下几个值:
* `ExitThread` 或 `TerminateThread` 函数中的指定退出值
* 线程函数的返回值
* 线程的进程退出值

> 重要: `GetExitCodeThread` 函数返回一个被应用程序在线程终止后定义的有效错误码。 因此应用程序不应使用 `STILL_ACTIVE(259)` 作为错误码。假如一个线程返回 `STILL_ACTIVE(259)` 作为错误码的话，应用程序将会检查该错误码认为该线程仍在运行，从而导致死循环。为了避免这个问题，调用者应该在确定县城已经退出后再调用`GetExitCodeThread`函数。 使用等待持续时间为零的 `WaitForSingleObject` 函数来确定线程是否已退出。

## [WaitForSingleObject function (synchapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitforsingleobject)

等待直到指定的对象处于信号状态或超时.

进入 alertable wait 状态使用 `[WaitForSingleObjectEx](https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitforsingleobjectex)` 函数. 等待多个对象, 使用 `[WaitForMultipleObjects](https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitformultipleobjects)`

```c++
DWORD WaitForSingleObject(
  [in] HANDLE hHandle,
  [in] DWORD  dwMilliseconds
);
```

### 参数

#### [in] hHandle

对象的句柄。 有关可以指定句柄的对象类型的列表，请参阅以下备注部分。

如果在等待仍处于挂起状态时关闭此句柄，则函数的行为未定义。

句柄必须具有 SYNCHRONIZE 访问权限。 有关详细信息，请参阅[Standard Access Rights](https://docs.microsoft.com/en-us/windows/win32/secauthz/standard-access-rights)

#### [in] dwMilliseconds

超时间隔，以毫秒为单位。 如果指定了非零值，则函数会一直等待，直到对象发出信号或超时。 如果 dwMilliseconds 为零，则如果对象未发出信号，则函数不会进入等待状态； 它总是立即返回。 如果 dwMilliseconds 为 INFINITE，则该函数仅在对象发出信号时返回。

Windows XP, Windows Server 2003, Windows Vista, Windows 7, Windows Server 2008 and Windows Server 2008 R2: dwMilliseconds 值确实包括在低功耗状态下花费的时间。 例如，当计算机处于睡眠状态时，超时确实会一直倒计时。

Windows 8, Windows Server 2012, Windows 8.1, Windows Server 2012 R2, Windows 10 and Windows Server 2016: dwMilliseconds 值不包括在低功耗状态下花费的时间。 例如，当计算机处于睡眠状态时，超时不会继续倒计时。

### 返回值

如果函数成功，则返回值指示导致函数返回的事件。 它可以是以下值之一。

|返回值|描述|
|-|-|
|WAIT_ABANDONED
0x00000080L|指定的对象是一个互斥对象，在拥有该互斥对象的线程终止之前，该对象没有被拥有该对象的线程释放。 互斥对象的所有权被授予调用线程，并且互斥状态设置为无信号。
如果互斥体正在保护持久状态信息，您应该检查它的一致性。|
|WAIT_TIMEOUT
0x00000102L|超时间隔已过，对象的状态为无信号状态。|
|WAIT_FAILED
(DWORD)0xFFFFFFFF|函数执行失败，使用 `GetLastError` 获得更多错误信息 |

### 注释

WaitForSingleObject 函数检查指定对象的当前状态。 如果对象的状态是无信号的，则调用线程进入等待状态，直到对象发出信号或超时间隔过去。该函数修改某些类型的同步对象的状态。 修改仅针对其信号状态导致函数返回的对象。 例如，信号量对象的计数减一。

WaitForSingleObject 函数可以等待以下对象：

* Change notification
* Console input
* Event
* Memory resource notification
* Mutex
* Process
* Semaphore
* Thread
* Waitable timer

调用直接或间接创建窗口的等待函数和代码时要小心。 如果线程创建任何窗口，它必须处理消息。 消息广播被发送到系统中的所有窗口。 使用没有超时间隔的等待函数的线程可能会导致系统死锁。间接创建窗口的两个代码示例是 DDE 和 CoInitialize 函数。 因此，如果您有创建窗口的线程，请使用 MsgWaitForMultipleObjects 或 MsgWaitForMultipleObjectsEx，而不是 WaitForSingleObject。

例子:

```c++
#include <windows.h>
#include <stdio.h>

#define THREADCOUNT 2

HANDLE ghMutex;

DWORD WINAPI WriteToDatabase( LPVOID );

int main( void )
{
    HANDLE aThread[THREADCOUNT];
    DWORD ThreadID;
    int i;

    // Create a mutex with no initial owner

    ghMutex = CreateMutex(
        NULL,              // default security attributes
        FALSE,             // initially not owned
        NULL);             // unnamed mutex

    if (ghMutex == NULL)
    {
        printf("CreateMutex error: %d\n", GetLastError());
        return 1;
    }

    // Create worker threads

    for( i=0; i < THREADCOUNT; i++ )
    {
        aThread[i] = CreateThread(
                     NULL,       // default security attributes
                     0,          // default stack size
                     (LPTHREAD_START_ROUTINE) WriteToDatabase,
                     NULL,       // no thread function arguments
                     0,          // default creation flags
                     &ThreadID); // receive thread identifier

        if( aThread[i] == NULL )
        {
            printf("CreateThread error: %d\n", GetLastError());
            return 1;
        }
    }

    // Wait for all threads to terminate

    WaitForMultipleObjects(THREADCOUNT, aThread, TRUE, INFINITE);

    // Close thread and mutex handles

    for( i=0; i < THREADCOUNT; i++ )
        CloseHandle(aThread[i]);

    CloseHandle(ghMutex);

    return 0;
}

DWORD WINAPI WriteToDatabase( LPVOID lpParam )
{
    // lpParam not used in this example
    UNREFERENCED_PARAMETER(lpParam);

    DWORD dwCount=0, dwWaitResult;

    // Request ownership of mutex.

    while( dwCount < 20 )
    {
        dwWaitResult = WaitForSingleObject(
            ghMutex,    // handle to mutex
            INFINITE);  // no time-out interval

        switch (dwWaitResult)
        {
            // The thread got ownership of the mutex
            case WAIT_OBJECT_0:
                __try {
                    // TODO: Write to the database
                    printf("Thread %d writing to database...\n",
                            GetCurrentThreadId());
                    dwCount++;
                }

                __finally {
                    // Release ownership of the mutex object
                    if (! ReleaseMutex(ghMutex))
                    {
                        // Handle error.
                    }
                }
                break;

            // The thread got ownership of an abandoned mutex
            // The database is in an indeterminate state
            case WAIT_ABANDONED:
                return FALSE;
        }
    }
    return TRUE;
}
```

## [WaitForSingleObjectEx function (synchapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitforsingleobjectex)

等待直到指定对象处于信号状态，I/O 完成例程或异步过程调用 (APC) 排队到线程，或者超时。

要等待多个对象，请使用 WaitForMultipleObjectsEx。

```c++
DWORD WaitForSingleObjectEx(
  [in] HANDLE hHandle,
  [in] DWORD  dwMilliseconds,
  [in] BOOL   bAlertable
);
```

### 参数

#### [in] hHandle

对象的句柄。 有关可以指定句柄的对象类型的列表，请参阅以下备注部分。

如果在等待仍处于挂起状态时关闭此句柄，则函数的行为未定义。

句柄必须具有 SYNCHRONIZE 访问权限。 有关详细信息，请参阅标准访问权限。

#### [in] dwMilliseconds

超时间隔，以毫秒为单位。 如果指定了非零值，则函数将一直等待，直到对象发出信号、I/O 完成例程或 APC 排队或间隔结束。 如果 dwMilliseconds 为零，则如果不满足条件，函数不会进入等待状态； 它总是立即返回。 如果 dwMilliseconds 为 INFINITE，则该函数仅在对象发出信号或 I/O 完成例程或 APC 排队时返回。

Windows XP, Windows Server 2003, Windows Vista, Windows 7, Windows Server 2008 and Windows Server 2008 R2: dwMilliseconds 值确实包括在低功耗状态下花费的时间。 例如，当计算机处于睡眠状态时，超时确实会一直倒计时。

Windows 8, Windows Server 2012, Windows 8.1, Windows Server 2012 R2, Windows 10 and Windows Server 2016:dwMilliseconds 值不包括在低功耗状态下花费的时间。 例如，当计算机处于睡眠状态时，超时不会继续倒计时。

#### [in] bAlertable

如果此参数为 TRUE 且线程处于等待状态，则当系统将 I/O 完成例程或 APC 排队时，该函数返回，并且线程运行该例程或函数。 否则，函数不返回，完成例程或 APC 函数不执行。

当指定完成例程的 ReadFileEx 或 WriteFileEx 函数完成时，完成例程将排队。 等待函数返回并仅当 bAlertable 为 TRUE 时才调用完成例程，并且调用线程是启动读取或写入操作的线程。 当您调用 QueueUserAPC 时，APC 将排队。

### 返回值

如果函数成功，则返回值指示导致函数返回的事件。 它可以是以下值之一。

|返回值|意义|
|-|-|
|WAIT_ABANDONED
0x00000080L|指定的对象是一个互斥对象，在拥有该互斥对象的线程终止之前，该对象没有被拥有该对象的线程释放。 互斥对象的所有权被授予调用线程，并且互斥对象被设置为无信号。
如果互斥体正在保护持久状态信息，您应该检查它的一致性。|
|WAIT_IO_COMPLETION
0x000000C0L|等待由排队到线程的一个或多个用户模式异步过程调用 (APC) 结束。|
|WAIT_OBJECT_0
0x00000000L|指定对象的状态被通知。|
|WAIT_TIMEOUT
0x00000102L|超时间隔已过，对象的状态为无信号状态。|
|WAIT_FAILED
(DWORD)0xFFFFFFFF|功能失败。 调用GetLastError， 获取扩展错误信息 |

### 备注

WaitForSingleObjectEx 函数确定是否满足等待条件。 如果条件未满足，则调用线程进入等待状态，直到满足等待条件的条件或超时间隔过去。

该函数修改某些类型的同步对象的状态。 修改仅针对其信号状态导致函数返回的对象。 例如，信号量对象的计数减一。

WaitForSingleObjectEx 函数可以等待以下对象：

* Change notification
* Console input
* Event
* Memory resource notification
* Mutex
* Process
* Semaphore
* Thread
* Waitable timer

调用直接或间接创建窗口的等待函数和代码时要小心。 如果线程创建任何窗口，它必须处理消息。 消息广播被发送到系统中的所有窗口。 使用没有超时间隔的等待函数的线程可能会导致系统死锁。 间接创建窗口的两个代码示例是 DDE 和 CoInitialize 函数。 因此，如果您有创建窗口的线程，请使用 MsgWaitForMultipleObjects 或 MsgWaitForMultipleObjectsEx，而不是 WaitForSingleObjectEx。

```c++
#include <windows.h>
#include <stdio.h>
#include <tchar.h>
#include <strsafe.h>

#define PIPE_TIMEOUT 5000
#define BUFSIZE 4096

typedef struct
{
   OVERLAPPED oOverlap;
   HANDLE hPipeInst;
   TCHAR chRequest[BUFSIZE];
   DWORD cbRead;
   TCHAR chReply[BUFSIZE];
   DWORD cbToWrite;
} PIPEINST, *LPPIPEINST;

VOID DisconnectAndClose(LPPIPEINST);
BOOL CreateAndConnectInstance(LPOVERLAPPED);
BOOL ConnectToNewClient(HANDLE, LPOVERLAPPED);
VOID GetAnswerToRequest(LPPIPEINST);

VOID WINAPI CompletedWriteRoutine(DWORD, DWORD, LPOVERLAPPED);
VOID WINAPI CompletedReadRoutine(DWORD, DWORD, LPOVERLAPPED);

HANDLE hPipe;

int _tmain(VOID)
{
   HANDLE hConnectEvent;
   OVERLAPPED oConnect;
   LPPIPEINST lpPipeInst;
   DWORD dwWait, cbRet;
   BOOL fSuccess, fPendingIO;

// Create one event object for the connect operation.

   hConnectEvent = CreateEvent(
      NULL,    // default security attribute
      TRUE,    // manual reset event
      TRUE,    // initial state = signaled
      NULL);   // unnamed event object

   if (hConnectEvent == NULL)
   {
      printf("CreateEvent failed with %d.\n", GetLastError());
      return 0;
   }

   oConnect.hEvent = hConnectEvent;

// Call a subroutine to create one instance, and wait for
// the client to connect.

   fPendingIO = CreateAndConnectInstance(&oConnect);

   while (1)
   {
   // Wait for a client to connect, or for a read or write
   // operation to be completed, which causes a completion
   // routine to be queued for execution.

      dwWait = WaitForSingleObjectEx(
         hConnectEvent,  // event object to wait for
         INFINITE,       // waits indefinitely
         TRUE);          // alertable wait enabled

      switch (dwWait)
      {
      // The wait conditions are satisfied by a completed connect
      // operation.
         case 0:
         // If an operation is pending, get the result of the
         // connect operation.

         if (fPendingIO)
         {
            fSuccess = GetOverlappedResult(
               hPipe,     // pipe handle
               &oConnect, // OVERLAPPED structure
               &cbRet,    // bytes transferred
               FALSE);    // does not wait
            if (!fSuccess)
            {
               printf("ConnectNamedPipe (%d)\n", GetLastError());
               return 0;
            }
         }

         // Allocate storage for this instance.

            lpPipeInst = (LPPIPEINST) GlobalAlloc(
               GPTR, sizeof(PIPEINST));
            if (lpPipeInst == NULL)
            {
               printf("GlobalAlloc failed (%d)\n", GetLastError());
               return 0;
            }

            lpPipeInst->hPipeInst = hPipe;

         // Start the read operation for this client.
         // Note that this same routine is later used as a
         // completion routine after a write operation.

            lpPipeInst->cbToWrite = 0;
            CompletedWriteRoutine(0, 0, (LPOVERLAPPED) lpPipeInst);

         // Create new pipe instance for the next client.

            fPendingIO = CreateAndConnectInstance(
               &oConnect);
            break;

      // The wait is satisfied by a completed read or write
      // operation. This allows the system to execute the
      // completion routine.

         case WAIT_IO_COMPLETION:
            break;

      // An error occurred in the wait function.

         default:
         {
            printf("WaitForSingleObjectEx (%d)\n", GetLastError());
            return 0;
         }
      }
   }
   return 0;
}

// CompletedWriteRoutine(DWORD, DWORD, LPOVERLAPPED)
// This routine is called as a completion routine after writing to
// the pipe, or when a new client has connected to a pipe instance.
// It starts another read operation.

VOID WINAPI CompletedWriteRoutine(DWORD dwErr, DWORD cbWritten,
   LPOVERLAPPED lpOverLap)
{
   LPPIPEINST lpPipeInst;
   BOOL fRead = FALSE;

// lpOverlap points to storage for this instance.

   lpPipeInst = (LPPIPEINST) lpOverLap;

// The write operation has finished, so read the next request (if
// there is no error).

   if ((dwErr == 0) && (cbWritten == lpPipeInst->cbToWrite))
      fRead = ReadFileEx(
         lpPipeInst->hPipeInst,
         lpPipeInst->chRequest,
         BUFSIZE*sizeof(TCHAR),
         (LPOVERLAPPED) lpPipeInst,
         (LPOVERLAPPED_COMPLETION_ROUTINE) CompletedReadRoutine);

// Disconnect if an error occurred.

   if (! fRead)
      DisconnectAndClose(lpPipeInst);
}

// CompletedReadRoutine(DWORD, DWORD, LPOVERLAPPED)
// This routine is called as an I/O completion routine after reading
// a request from the client. It gets data and writes it to the pipe.

VOID WINAPI CompletedReadRoutine(DWORD dwErr, DWORD cbBytesRead,
    LPOVERLAPPED lpOverLap)
{
   LPPIPEINST lpPipeInst;
   BOOL fWrite = FALSE;

// lpOverlap points to storage for this instance.

   lpPipeInst = (LPPIPEINST) lpOverLap;

// The read operation has finished, so write a response (if no
// error occurred).

   if ((dwErr == 0) && (cbBytesRead != 0))
   {
      GetAnswerToRequest(lpPipeInst);

      fWrite = WriteFileEx(
         lpPipeInst->hPipeInst,
         lpPipeInst->chReply,
         lpPipeInst->cbToWrite,
         (LPOVERLAPPED) lpPipeInst,
         (LPOVERLAPPED_COMPLETION_ROUTINE) CompletedWriteRoutine);
   }

// Disconnect if an error occurred.

   if (! fWrite)
      DisconnectAndClose(lpPipeInst);
}

// DisconnectAndClose(LPPIPEINST)
// This routine is called when an error occurs or the client closes
// its handle to the pipe.

VOID DisconnectAndClose(LPPIPEINST lpPipeInst)
{
// Disconnect the pipe instance.

   if (! DisconnectNamedPipe(lpPipeInst->hPipeInst) )
   {
      printf("DisconnectNamedPipe failed with %d.\n", GetLastError());
   }

// Close the handle to the pipe instance.

   CloseHandle(lpPipeInst->hPipeInst);

// Release the storage for the pipe instance.

   if (lpPipeInst != NULL)
      GlobalFree(lpPipeInst);
}

// CreateAndConnectInstance(LPOVERLAPPED)
// This function creates a pipe instance and connects to the client.
// It returns TRUE if the connect operation is pending, and FALSE if
// the connection has been completed.

BOOL CreateAndConnectInstance(LPOVERLAPPED lpoOverlap)
{
   LPTSTR lpszPipename = TEXT("\\\\.\\pipe\\mynamedpipe");

   hPipe = CreateNamedPipe(
      lpszPipename,             // pipe name
      PIPE_ACCESS_DUPLEX |      // read/write access
      FILE_FLAG_OVERLAPPED,     // overlapped mode
      PIPE_TYPE_MESSAGE |       // message-type pipe
      PIPE_READMODE_MESSAGE |   // message read mode
      PIPE_WAIT,                // blocking mode
      PIPE_UNLIMITED_INSTANCES, // unlimited instances
      BUFSIZE*sizeof(TCHAR),    // output buffer size
      BUFSIZE*sizeof(TCHAR),    // input buffer size
      PIPE_TIMEOUT,             // client time-out
      NULL);                    // default security attributes
   if (hPipe == INVALID_HANDLE_VALUE)
   {
      printf("CreateNamedPipe failed with %d.\n", GetLastError());
      return 0;
   }

// Call a subroutine to connect to the new client.

   return ConnectToNewClient(hPipe, lpoOverlap);
}

BOOL ConnectToNewClient(HANDLE hPipe, LPOVERLAPPED lpo)
{
   BOOL fConnected, fPendingIO = FALSE;

// Start an overlapped connection for this pipe instance.
   fConnected = ConnectNamedPipe(hPipe, lpo);

// Overlapped ConnectNamedPipe should return zero.
   if (fConnected)
   {
      printf("ConnectNamedPipe failed with %d.\n", GetLastError());
      return 0;
   }

   switch (GetLastError())
   {
   // The overlapped connection in progress.
      case ERROR_IO_PENDING:
         fPendingIO = TRUE;
         break;

   // Client is already connected, so signal an event.

      case ERROR_PIPE_CONNECTED:
         if (SetEvent(lpo->hEvent))
            break;

   // If an error occurs during the connect operation...
      default:
      {
         printf("ConnectNamedPipe failed with %d.\n", GetLastError());
         return 0;
      }
   }
   return fPendingIO;
}

VOID GetAnswerToRequest(LPPIPEINST pipe)
{
   _tprintf( TEXT("[%d] %s\n"), pipe->hPipeInst, pipe->chRequest);
   StringCchCopy( pipe->chReply, BUFSIZE, TEXT("Default answer from server") );
   pipe->cbToWrite = (lstrlen(pipe->chReply)+1)*sizeof(TCHAR);
}
```

## [WaitForMultipleObjects function (synchapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-waitformultipleobjects)

等待直到一个或所有指定对象处于信号状态或超时。

要进入警报等待状态，请使用 WaitForMultipleObjectsEx 函数。

```c++
DWORD WaitForMultipleObjects(
  [in] DWORD        nCount,
  [in] const HANDLE *lpHandles,
  [in] BOOL         bWaitAll,
  [in] DWORD        dwMilliseconds
);
```

### 参数

#### [in] nCount

lpHandles 指向的数组中对象句柄的数量。 对象句柄的最大数量是 MAXIMUM_WAIT_OBJECTS。 此参数不能为零。

#### [in] lpHandles

对象句柄数组。 有关可以指定句柄的对象类型的列表，请参阅以下备注部分。 该数组可以包含不同类型对象的句柄。 它可能不包含同一句柄的多个副本。

如果这些句柄之一在等待仍处于挂起状态时关闭，则函数的行为未定义。

句柄必须具有 SYNCHRONIZE 访问权限。 有关详细信息，请参阅标准访问权限。

#### [in] bWaitAll

如果此参数为 TRUE，则函数会在 lpHandles 数组中所有对象的状态发出信号时返回。 如果为 FALSE，则函数在任何一个对象的状态设置为已发出信号时返回。 在后一种情况下，返回值指示其状态导致函数返回的对象。

#### [in] dwMilliseconds

超时间隔，以毫秒为单位。 如果指定了非零值，则函数将一直等待，直到指定对象发出信号或间隔过去。 如果 dwMilliseconds 为零，如果指定的对象没有发出信号，则函数不会进入等待状态； 它总是立即返回。 如果 dwMilliseconds 为 INFINITE，则该函数仅在指定对象发出信号时返回。

Windows XP, Windows Server 2003, Windows Vista, Windows 7, Windows Server 2008 and Windows Server 2008 R2: dwMilliseconds 值确实包括在低功耗状态下花费的时间。 例如，当计算机处于睡眠状态时，超时确实会一直倒计时。

Windows 8, Windows Server 2012, Windows 8.1, Windows Server 2012 R2, Windows 10 and Windows Server 2016: dwMilliseconds 值不包括在低功耗状态下花费的时间。 例如，当计算机处于睡眠状态时，超时不会继续倒计时。

### 返回值

如果函数成功，则返回值指示导致函数返回的事件。 它可以是以下值之一。（注意，WAIT_OBJECT_0 定义为 0，WAIT_ABANDONED_0 定义为 0x00000080L。）

|返回值|描述|
|-|-|
|WAIT_OBJECT_0 to (WAIT_OBJECT_0 + nCount– 1)| 如果 bWaitAll 为 TRUE，则指定范围内的返回值指示所有指定对象的状态都已发出信号。
如果 bWaitAll 为 FALSE，则返回值减去 WAIT_OBJECT_0 表示满足等待的对象的 lpHandles 数组索引。 如果在调用过程中有多个对象发出信号，则这是所有已发出信号对象中索引值最小的已发出信号对象的数组索引。 |
|WAIT_ABANDONED_0 to (WAIT_ABANDONED_0 + nCount– 1)|如果 bWaitAll 为 TRUE，则指定范围内的返回值表示所有指定对象的状态都已发出信号，并且至少有一个对象是废弃的互斥对象。
如果 bWaitAll 为 FALSE，则返回值减去 WAIT_ABANDONED_0 表示满足等待的废弃互斥对象的 lpHandles 数组索引。 互斥对象的所有权被授予调用线程，并且互斥对象被设置为无信号。

如果互斥体正在保护持久状态信息，您应该检查它的一致性。|
|WAIT_TIMEOUT 0x00000102L|超时间隔已过且不满足 bWaitAll 参数指定的条件。|
|WAIT_FAILED
(DWORD)0xFFFFFFFF|功能失败。 要获取扩展错误信息，请调用 GetLastError。|

### 附注

WaitForMultipleObjects 函数确定是否满足等待条件。 如果条件未满足，则调用线程进入等待状态，直到满足等待条件的条件或超时间隔过去。

当 bWaitAll 为 TRUE 时，只有当所有对象的状态都设置为 signaled 时，函数的等待操作才完成。 在所有对象的状态都设置为已发出信号之前，该函数不会修改指定对象的状态。 例如，可以用信号通知互斥体，但在其他对象的状态也设置为已发出信号之前，线程不会获得所有权。 与此同时，其他一些线程可能会获得互斥锁的所有权，从而将其状态设置为非信号。

当 bWaitAll 为 FALSE 时，此函数按从索引 0 开始的顺序检查数组中的句柄，直到其中一个对象发出信号。 如果多个对象变为信号，则该函数返回数组中第一个句柄的索引，其对象被信号。

该函数修改某些类型的同步对象的状态。 修改仅针对其信号状态导致函数返回的一个或多个对象。 例如，信号量对象的计数减一。 有关详细信息，请参阅各个同步对象的文档。

要等待超过 MAXIMUM_WAIT_OBJECTS 个句柄，请使用以下方法之一：

* 创建一个线程以等待 MAXIMUM_WAIT_OBJECTS 句柄，然后在该线程和其他句柄上等待。 使用此技术将句柄分成 MAXIMUM_WAIT_OBJECTS 组。

* 调用 RegisterWaitForSingleObject 以等待每个句柄。 线程池中的等待线程等待 MAXIMUM_WAIT_OBJECTS 注册对象，并在对象发出信号或超时间隔到期后分配一个工作线程。

WaitForMultipleObjects 函数可以在 lpHandles 数组中指定以下任何对象类型的句柄：

* Change notification
* Console input
* Event
* Memory resource notification
* Mutex
* Process
* Semaphore
* Thread
* Waitable timer

调用直接或间接创建窗口的等待函数和代码时要小心。 如果线程创建任何窗口，它必须处理消息。 消息广播被发送到系统中的所有窗口。 使用没有超时间隔的等待函数的线程可能会导致系统死锁。 间接创建窗口的两个代码示例是 DDE 和 CoInitialize 函数。 因此，如果您有创建窗口的线程，请使用 MsgWaitForMultipleObjects 或 MsgWaitForMultipleObjectsEx，而不是 WaitForMultipleObjects。


```c++
#include <windows.h>
#include <stdio.h>

HANDLE ghEvents[2];

DWORD WINAPI ThreadProc( LPVOID );

int main( void )
{
    HANDLE hThread;
    DWORD i, dwEvent, dwThreadID;

    // Create two event objects

    for (i = 0; i < 2; i++)
    {
        ghEvents[i] = CreateEvent(
            NULL,   // default security attributes
            FALSE,  // auto-reset event object
            FALSE,  // initial state is nonsignaled
            NULL);  // unnamed object

        if (ghEvents[i] == NULL)
        {
            printf("CreateEvent error: %d\n", GetLastError() );
            ExitProcess(0);
        }
    }

    // Create a thread

    hThread = CreateThread(
                 NULL,         // default security attributes
                 0,            // default stack size
                 (LPTHREAD_START_ROUTINE) ThreadProc,
                 NULL,         // no thread function arguments
                 0,            // default creation flags
                 &dwThreadID); // receive thread identifier

    if( hThread == NULL )
    {
        printf("CreateThread error: %d\n", GetLastError());
        return 1;
    }

    // Wait for the thread to signal one of the event objects

    dwEvent = WaitForMultipleObjects(
        2,           // number of objects in array
        ghEvents,     // array of objects
        FALSE,       // wait for any object
        5000);       // five-second wait

    // The return value indicates which event is signaled

    switch (dwEvent)
    {
        // ghEvents[0] was signaled
        case WAIT_OBJECT_0 + 0:
            // TODO: Perform tasks required by this event
            printf("First event was signaled.\n");
            break;

        // ghEvents[1] was signaled
        case WAIT_OBJECT_0 + 1:
            // TODO: Perform tasks required by this event
            printf("Second event was signaled.\n");
            break;

        case WAIT_TIMEOUT:
            printf("Wait timed out.\n");
            break;

        // Return value is invalid.
        default:
            printf("Wait error: %d\n", GetLastError());
            ExitProcess(0);
    }

    // Close event handles

    for (i = 0; i < 2; i++)
        CloseHandle(ghEvents[i]);

    return 0;
}

DWORD WINAPI ThreadProc( LPVOID lpParam )
{

    // lpParam not used in this example
    UNREFERENCED_PARAMETER( lpParam);

    // Set one event to the signaled state

    if ( !SetEvent(ghEvents[0]) )
    {
        printf("SetEvent failed (%d)\n", GetLastError());
        return 1;
    }
    return 0;
}
```

## [_beginthread, _beginthreadex](https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/beginthread-beginthreadex?view=msvc-170)

创建一个线程

```c++
uintptr_t _beginthread( // NATIVE CODE
   void( __cdecl *start_address )( void * ),
   unsigned stack_size,
   void *arglist
);
uintptr_t _beginthread( // MANAGED CODE
   void( __clrcall *start_address )( void * ),
   unsigned stack_size,
   void *arglist
);
uintptr_t _beginthreadex( // NATIVE CODE
   void *security,
   unsigned stack_size,
   unsigned ( __stdcall *start_address )( void * ),
   void *arglist,
   unsigned initflag,
   unsigned *thrdaddr
);
uintptr_t _beginthreadex( // MANAGED CODE
   void *security,
   unsigned stack_size,
   unsigned ( __clrcall *start_address )( void * ),
   void *arglist,
   unsigned initflag,
   unsigned *thrdaddr
);
```

### 参数

#### start_address

开始执行新线程的例程的起始地址。 对于 _beginthread，调用约定是 __cdecl（对于本机代码）或 __clrcall（对于托管代码）； 对于 _beginthreadex，它是 __stdcall（对于本机代码）或 __clrcall（对于托管代码）。

#### stack_size

新线程的堆栈大小，或 0(使用系统默认栈大小)

#### arglist

要传递给新线程的参数列表，或 NULL。

#### Security

指向 SECURITY_ATTRIBUTES 结构的指针，该结构确定返回的句柄是否可以被子进程继承。 如果 Security 为 NULL，则不能继承句柄。 对于 Windows 95 应用程序必须为 NULL。

#### initflag

控制新线程初始状态的标志。 将 initflag 设置为 0 以立即运行，或者设置为 CREATE_SUSPENDED 以创建处于挂起状态的线程； 使用 ResumeThread 执行线程。 将 initflag 设置为 STACK_SIZE_PARAM_IS_A_RESERVATION 标志以使用 stack_size 作为堆栈的初始保留大小（以字节为单位）； 如果未指定此标志，则 stack_size 指定提交大小。

#### thrdaddr

指向接收线程标识符的 32 位变量。 如果为 NULL，则不使用。

### 返回值

如果成功，这些函数中的每一个都会返回一个新创建线程的句柄； 但是，如果新创建的线程退出太快，_beginthread 可能不会返回有效句柄。 （请参阅备注部分中的讨论。）发生错误时，_beginthread 返回 -1L，如果线程太多，则将 errno 设置为 EAGAIN，如果参数无效或堆栈大小不正确，则设置为 EINVAL，如果 资源不足（如内存）。 发生错误时，_beginthreadex 返回 0，并设置 errno 和 _doserrno。

如果 start_address 为 NULL，则调用无效参数处理程序，如参数验证中所述。 如果允许继续执行，这些函数将 errno 设置为 EINVAL 并返回 -1。

有关这些和其他返回代码的详细信息，请参阅 errno、_doserrno、_sys_errlist 和 _sys_nerr。

### 附注

_beginthread 函数创建一个在 start_address 处开始执行例程的线程。 start_address 处的例程必须使用 __cdecl（对于本机代码）或 __clrcall（对于托管代码）调用约定，并且应该没有返回值。 当线程从该例程返回时，它会自动终止。 有关线程的更多信息，请参阅旧代码的多线程支持 (Visual C++)。

_beginthreadex 比 _beginthread 更类似于 Win32 CreateThread API。 _beginthreadex 在以下方面与 _beginthread 不同：

* _beginthreadex 具有三个附加参数：initflag、Security 和 threadaddr。 新线程可以在挂起状态下创建，具有指定的安全性，并且可以使用线程标识符 thrdaddr 访问。
* _beginthreadex 在失败时返回 0，而不是 -1L。
* 使用 _beginthreadex 创建的线程通过调用 _endthreadex 终止。

_beginthreadex 函数使您可以比 _beginthread 更好地控制线程的创建方式。 _endthreadex 函数也更加灵活。 例如，使用_beginthreadex，您可以使用安全信息，设置线程的初始状态（运行或挂起），并获取新创建线程的线程标识符。 您还可以将 _beginthreadex 返回的线程句柄与同步 API 一起使用，而 _beginthread 则无法做到这一点。

使用 _beginthreadex 比使用 _beginthread 更安全。 如果 _beginthread 生成的线程快速退出，则返回给 _beginthread 调用者的句柄可能无效或指向另一个线程。 但是，_beginthreadex 返回的句柄必须由_beginthreadex 的调用者关闭，因此如果_beginthreadex 没有返回错误，则可以保证它是有效的句柄。

可以显式调用 _endthread 或 _endthreadex 来终止线程； 但是，当线程从作为参数传递的例程返回时，会自动调用 _endthread 或 _endthreadex。 通过调用 _endthread 或 _endthreadex 来终止线程有助于确保正确恢复为线程分配的资源。

_endthread 会自动关闭线程句柄，而 _endthreadex 不会。 因此，当您使用 _beginthread 和 _endthread 时，不要通过调用 Win32 CloseHandle API 显式关闭线程句柄。 此行为不同于 Win32 ExitThread API。

对于与 Libcmt.lib 链接的可执行文件，不要调用 Win32 ExitThread API，以免阻止运行时系统回收分配的资源。 _endthread 和 _endthreadex 回收分配的线程资源，然后调用 ExitThread。

操作系统在调用 _beginthread 或 _beginthreadex 时处理堆栈的分配； 您不必将线程堆栈的地址传递给这些函数中的任何一个。 此外，stack_size 参数可以为 0，在这种情况下，操作系统使用与为主线程指定的堆栈相同的值。

arglist 是要传递给新创建线程的参数。 通常，它是数据项的地址，例如字符串。 如果不需要 arglist 可以为 NULL，但必须为 _beginthread 和 _beginthreadex 赋予一些值才能传递给新线程。 如果任何线程调用 abort、exit、_exit 或 ExitProcess，所有线程都将终止。

新线程的语言环境是通过使用每个进程的全局当前语言环境信息来初始化的。 如果通过调用 _configthreadlocale（全局或仅用于新线程）启用了每个线程的区域设置，则线程可以通过调用 setlocale 或 _wsetlocale 独立于其他线程更改其区域设置。 没有设置每线程语言环境标志的线程会影响所有其他也没有设置每线程语言环境标志的线程以及所有新创建的线程中的语言环境信息。 有关详细信息，请参阅[Locale](https://docs.microsoft.com/en-us/cpp/c-runtime-library/locale?view=msvc-170)。

对于 /clr 代码，_beginthread 和 _beginthreadex 各有两个重载。 一个采用本机调用约定函数指针，另一个采用 __clrcall 函数指针。 第一个重载不是应用程序域安全的，而且永远不会。 如果您正在编写 /clr 代码，则必须确保新线程在访问托管资源之前进入正确的应用程序域。 例如，您可以通过使用 call_in_appdomain 函数来做到这一点。 第二个重载是应用程序域安全的； 新创建的线程将始终在 _beginthread 或 _beginthreadex 的调用者的应用程序域中结束。

默认情况下，此函数的全局状态仅限于应用程序。 要更改此设置，请参阅 [Global state in the CRT](https://docs.microsoft.com/en-us/cpp/c-runtime-library/global-state?view=msvc-170)

### 例子

```c++
// crt_BEGTHRD.C
// compile with: /MT /D "_X86_" /c
// processor: x86
#include <windows.h>
#include <process.h>    /* _beginthread, _endthread */
#include <stddef.h>
#include <stdlib.h>
#include <conio.h>

void Bounce( void * );
void CheckKey( void * );

// GetRandom returns a random integer between min and max.
#define GetRandom( min, max ) ((rand() % (int)(((max) + 1) - (min))) + (min))
// GetGlyph returns a printable ASCII character value
#define GetGlyph( val ) ((char)((val + 32) % 93 + 33))

BOOL repeat = TRUE;                 // Global repeat flag
HANDLE hStdOut;                     // Handle for console window
CONSOLE_SCREEN_BUFFER_INFO csbi;    // Console information structure

int main()
{
    int param = 0;
    int * pparam = &param;

    // Get display screen's text row and column information.
    hStdOut = GetStdHandle( STD_OUTPUT_HANDLE );
    GetConsoleScreenBufferInfo( hStdOut, &csbi );

    // Launch CheckKey thread to check for terminating keystroke.
    _beginthread( CheckKey, 0, NULL );

    // Loop until CheckKey terminates program or 1000 threads created.
    while( repeat && param < 1000 )
    {
        // launch another character thread.
        _beginthread( Bounce, 0, (void *) pparam );

        // increment the thread parameter
        param++;

        // Wait one second between loops.
        Sleep( 1000L );
    }
}

// CheckKey - Thread to wait for a keystroke, then clear repeat flag.
void CheckKey( void * ignored )
{
    _getch();
    repeat = 0;    // _endthread implied
}

// Bounce - Thread to create and control a colored letter that moves
// around on the screen.
//
// Params: parg - the value to create the character from
void Bounce( void * parg )
{
    char       blankcell = 0x20;
    CHAR_INFO  ci;
    COORD      oldcoord, cellsize, origin;
    DWORD      result;
    SMALL_RECT region;

    cellsize.X = cellsize.Y = 1;
    origin.X = origin.Y = 0;

    // Generate location, letter and color attribute from thread argument.
    srand( _threadid );
    oldcoord.X = region.Left = region.Right =
        GetRandom(csbi.srWindow.Left, csbi.srWindow.Right - 1);
    oldcoord.Y = region.Top = region.Bottom =
        GetRandom(csbi.srWindow.Top, csbi.srWindow.Bottom - 1);
    ci.Char.AsciiChar = GetGlyph(*((int *)parg));
    ci.Attributes = GetRandom(1, 15);

    while (repeat)
    {
        // Pause between loops.
        Sleep( 100L );

        // Blank out our old position on the screen, and draw new letter.
        WriteConsoleOutputCharacterA(hStdOut, &blankcell, 1, oldcoord, &result);
        WriteConsoleOutputA(hStdOut, &ci, cellsize, origin, &region);

        // Increment the coordinate for next placement of the block.
        oldcoord.X = region.Left;
        oldcoord.Y = region.Top;
        region.Left = region.Right += GetRandom(-1, 1);
        region.Top = region.Bottom += GetRandom(-1, 1);

        // Correct placement (and beep) if about to go off the screen.
        if (region.Left < csbi.srWindow.Left)
            region.Left = region.Right = csbi.srWindow.Left + 1;
        else if (region.Right >= csbi.srWindow.Right)
            region.Left = region.Right = csbi.srWindow.Right - 2;
        else if (region.Top < csbi.srWindow.Top)
            region.Top = region.Bottom = csbi.srWindow.Top + 1;
        else if (region.Bottom >= csbi.srWindow.Bottom)
            region.Top = region.Bottom = csbi.srWindow.Bottom - 2;

        // If not at a screen border, continue, otherwise beep.
        else
            continue;
        Beep((ci.Char.AsciiChar - 'A') * 100, 175);
    }
    // _endthread given to terminate
    _endthread();
}
```

## [_endthread, _endthreadex](https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/endthread-endthreadex?view=msvc-170)

```c++
void _endthread( void );
void _endthreadex(
   unsigned retval
);
```

### 参数

#### 返回值

线程退出码

### 附注

您可以显式调用 _endthread 或 _endthreadex 来终止线程； 但是，当线程从作为参数传递给 _beginthread 或 _beginthreadex 的例程返回时，会自动调用 _endthread 或 _endthreadex。 通过调用 endthread 或 _endthreadex 来终止线程有助于确保正确恢复为线程分配的资源。

对于与 Libcmt.lib 链接的可执行文件，不要调用 Win32 ExitThread API； 这可以防止运行时系统回收分配的资源。 _endthread 和 _endthreadex 回收分配的线程资源，然后调用 ExitThread。

_endthread 自动关闭线程句柄。 （此行为与 Win32 ExitThread API 不同。）因此，当您使用 _beginthread 和 _endthread 时，不要通过调用 Win32 CloseHandle API 显式关闭线程句柄。

与 Win32 ExitThread API 一样，_endthreadex 不会关闭线程句柄。 因此，当您使用_beginthreadex 和_endthreadex 时，您必须通过调用Win32 CloseHandle API 来关闭线程句柄。

_endthread 和 _endthreadex 导致线程中挂起的 C++ 析构函数不被调用。

默认情况下，此函数的全局状态范围为应用程序。 要更改此设置，请参阅 CRT 中的全局状态。


## [InitializeConditionVariable function (synchapi.h)](https://docs.microsoft.com/zh-cn/windows/win32/api/synchapi/nf-synchapi-initializeconditionvariable)

```c++
void InitializeCriticalSection(
  [out] LPCRITICAL_SECTION lpCriticalSection
);
```

### 参数

#### [out] lpCriticalSection

指向临界区对象的指针

### 附注

一个进程的线程可以使用临界区对象来实现互斥同步。对于哪个线程获取临界区顺序没有保证，但系统对每个线程是公平的。

该进程负责分配临界区对象使用的内存，它可以通过声明 CRITICAL_SECTION 类型的变量来完成。在使用临界区之前，进程的某些线程必须初始化对象。

临界区对象初始化后，进程的线程可以在 EnterCriticalSection、TryEnterCriticalSection 或 LeaveCriticalSection 函数中指定该对象，以提供对共享资源的互斥访问。对于不同进程的线程之间的类似同步，请使用互斥对象。

不能移动或复制临界区对象。 该过程也不得修改对象，但必须将其视为逻辑上不透明的。 仅使用临界区函数来管理临界区对象。 使用完临界区后，调用 DeleteCriticalSection 函数。
必须先删除临界区对象，然后才能重新初始化它。 初始化已经初始化的临界区会导致未定义的行为。

## [EnterCriticalSection function (synchapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-entercriticalsection)

等待指定临界区对象的所有权。 当调用线程被授予所有权时，该函数返回。

```c++
void EnterCriticalSection(
  [in, out] LPCRITICAL_SECTION lpCriticalSection
);
```

### 参数

#### [in, out] lpCriticalSection

指向临界区对象的指针。

### 返回值

函数没有返回值

如果对关键部分的等待操作超时，此函数可以引发 EXCEPTION_POSSIBLE_DEADLOCK。超时间隔由以下注册表值指定`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\CriticalSectionTimeout`
不要处理可能的死锁异常； 相反，调试应用程序。

### 附注

单个进程的线程可以使用临界区对象进行互斥同步。 该进程负责分配临界区对象使用的内存，它可以通过声明 CRITICAL_SECTION 类型的变量来完成。 在使用临界区之前，进程的某些线程必须调用 InitializeCriticalSection 或 InitializeCriticalSectionAndSpinCount 来初始化对象。

为了启用对共享资源的互斥访问，每个线程调用 EnterCriticalSection 或 TryEnterCriticalSection 函数来请求临界区的所有权，然后再执行访问受保护资源的任何代码部分。 不同之处在于 TryEnterCriticalSection 会立即返回，而不管它是否获得了临界区的所有权，而 EnterCriticalSection 会阻塞，直到线程可以获得临界区的所有权。 执行完受保护代码后，线程使用 LeaveCriticalSection 函数放弃所有权，使另一个线程成为所有者并访问受保护资源。 无法保证等待线程获得临界区所有权的顺序。

在线程拥有临界区的所有权后，它可以对 EnterCriticalSection 或 TryEnterCriticalSection 进行额外调用，而不会阻止其执行。 这可以防止线程在等待它已经拥有的临界区时自行死锁。 每次 EnterCriticalSection 和 TryEnterCriticalSection 成功时线程进入临界区。 线程每次进入临界区时都必须调用一次 LeaveCriticalSection。

进程的任何线程都可以使用 DeleteCriticalSection 函数来释放在临界区对象初始化时分配的系统资源。 调用此函数后，临界区对象不能再用于同步。

如果线程在拥有临界区所有权时终止，则临界区的状态未定义。

如果一个临界区在它仍然拥有的情况下被删除，等待被删除临界区所有权的线程的状态是未定义的。

当进程退出时，如果对 EnterCriticalSection 的调用会阻塞，它将立即终止进程。 这可能会导致不调用全局析构函数。

### 例子

```c++
// Global variable
CRITICAL_SECTION CriticalSection;

int main( void )
{
    ...

    // Initialize the critical section one time only.
    if (!InitializeCriticalSectionAndSpinCount(&CriticalSection,
        0x00000400) )
        return;
    ...

    // Release resources used by the critical section object.
    DeleteCriticalSection(&CriticalSection);
}

DWORD WINAPI ThreadProc( LPVOID lpParameter )
{
    ...

    // Request ownership of the critical section.
    EnterCriticalSection(&CriticalSection);

    // Access the shared resource.

    // Release ownership of the critical section.
    LeaveCriticalSection(&CriticalSection);

    ...
return 1;
}
```

## [LeaveCriticalSection function (synchapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-leavecriticalsection)

释放指定临界区对象的所有权。

```c++
void LeaveCriticalSection(
  [in, out] LPCRITICAL_SECTION lpCriticalSection
);
```

### 参数

#### [in, out] lpCriticalSection

指向临界区对象的指针。

### 附注

单个进程的线程可以使用临界区对象进行互斥同步。 该进程负责分配临界区对象使用的内存，它可以通过声明 CRITICAL_SECTION 类型的变量来完成。

在使用临界区之前，进程的某些线程必须调用 InitializeCriticalSection 或 InitializeCriticalSectionAndSpinCount 函数来初始化对象。

线程使用 EnterCriticalSection 或 TryEnterCriticalSection 函数来获取临界区对象的所有权。 要释放其所有权，线程必须在每次进入临界区时调用一次 LeaveCriticalSection。

如果线程在没有指定临界区对象的所有权时调用 LeaveCriticalSection，则会发生错误，可能导致另一个使用 EnterCriticalSection 的线程无限期等待。

进程的任何线程都可以使用 DeleteCriticalSection 函数来释放在临界区对象初始化时分配的系统资源。 调用此函数后，临界区对象不能再用于同步。

## [CreateMutexA function (synchapi.h)](https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-createmutexa)

创建或打开一个命名或未命名的互斥对象。要为对象指定访问掩码，请使用 CreateMutexEx 函数。

```c++
HANDLE CreateMutexA(
  [in, optional] LPSECURITY_ATTRIBUTES lpMutexAttributes,
  [in]           BOOL                  bInitialOwner,
  [in, optional] LPCSTR                lpName
);
```

### 参数

#### [in, optional] lpMutexAttributes

指向 SECURITY_ATTRIBUTES 结构的指针。 如果该参数为NULL，则句柄不能被子进程继承。

结构的 lpSecurityDescriptor 成员指定新互斥体的安全描述符。 如果 lpMutexAttributes 为 NULL，则互斥锁获取默认安全描述符。 互斥锁的默认安全描述符中的 ACL 来自创建者的主令牌或模拟令牌。 有关详细信息，请参阅同步对象安全性和访问权限。

#### [in] bInitialOwner

如果此值为 TRUE 并且调用者创建了互斥锁，则调用线程将获得互斥锁对象的初始所有权。 否则，调用线程不会获得互斥锁的所有权。 要确定调用者是否创建了互斥锁，请参阅返回值部分。

#### [in, optional] lpName

互斥对象的名称。 该名称仅限于 MAX_PATH 个字符。 名称比较区分大小写。

如果 lpName 与现有命名互斥对象的名称匹配，则此函数请求 MUTEX_ALL_ACCESS 访问权限。 在这种情况下，将忽略 bInitialOwner 参数，因为它已由创建过程设置。 如果 lpMutexAttributes 参数不为 NULL，它决定句柄是否可以被继承，但它的 security-descriptor 成员被忽略。

如果 lpName 为 NULL，则创建互斥对象时没有名称。

如果 lpName 与现有事件、信号量、可等待计时器、作业或文件映射对象的名称匹配，则该函数将失败并且 GetLastError 函数返回 ERROR_INVALID_HANDLE。 这是因为这些对象共享相同的命名空间。

该名称可以具有“全局”或“本地”前缀，以在全局或会话命名空间中显式创建对象。 名称的其余部分可以包含除反斜杠字符 (\) 之外的任何字符。 有关详细信息，请参阅内核对象命名空间。 使用终端服务会话实现快速用户切换。 内核对象名称必须遵循为终端服务概述的准则，以便应用程序可以支持多个用户。

该对象可以在私有命名空间中创建。 有关详细信息，请参阅对象命名空间。

### 返回值

如果函数成功，则返回值是新创建的互斥对象的句柄。

如果函数失败，则返回值为 NULL。 要获取扩展错误信息，请调用 GetLastError。

如果互斥体是命名互斥体并且该对象在此函数调用之前存在，则返回值是现有对象的句柄，并且 GetLastError 函数返回 ERROR_ALREADY_EXISTS。

### 附注

CreateMutex 返回的句柄具有 MUTEX_ALL_ACCESS 访问权限； 它可以用于任何需要互斥对象句柄的函数，前提是调用者已被授予访问权限。 如果从模拟不同用户的服务或线程创建互斥锁，则可以在创建互斥锁时将安全描述符应用于互斥锁，或通过更改其默认 DACL 来更改创建进程的默认安全描述符。 有关详细信息，请参阅同步对象安全性和访问权限。

如果您使用命名互斥锁将应用程序限制为单个实例，则恶意用户可以在您创建此互斥锁之前创建此互斥锁并阻止您的应用程序启动。 为防止出现这种情况，请创建一个随机命名的互斥体并将名称存储起来，以便只能由授权用户获取。 或者，您可以为此目的使用文件。 要将您的应用程序限制为每个用户一个实例，请在用户的配置文件目录中创建一个锁定文件。

调用进程的任何线程都可以在调用其中一个等待函数时指定互斥对象句柄。 当指定对象的状态发出信号时，单对象等待函数返回。 可以指示多对象等待函数在任何一个对象或所有指定对象都收到信号时返回。 当等待函数返回时，等待线程被释放以继续执行。

当互斥对象不属于任何线程时，它的状态就会发出信号。 创建线程可以使用 bInitialOwner 标志来请求互斥锁的立即所有权。 否则，线程必须使用其中一个等待函数来请求所有权。 当互斥体的状态发出信号时，一个等待线程被授予所有权，互斥体的状态变为非信号状态，等待函数返回。 在任何给定时间，只有一个线程可以拥有互斥锁。 拥有线程使用 ReleaseMutex 函数释放其所有权。

拥有互斥锁的线程可以在重复的等待函数调用中指定相同的互斥锁，而不会阻塞其执行。 通常，您不会重复等待同一个互斥锁，但是这种机制可以防止线程在等待它已经拥有的互斥锁时使自己死锁。 但是，为了释放它的所有权，线程必须在互斥锁每次满足等待时调用一次 ReleaseMutex。

两个或多个进程可以调用 CreateMutex 来创建同名互斥锁。 第一个进程实际上创建了互斥锁，具有足够访问权限的后续进程只需打开现有互斥锁的句柄。 这使得多个进程能够获得同一个互斥锁的句柄，同时减轻了用户确保创建进程首先启动的责任。 使用此技术时，应将 bInitialOwner 标志设置为 FALSE； 否则，可能很难确定哪个进程具有初始所有权。

多个进程可以拥有同一个互斥对象的句柄，从而可以使用该对象进行进程间同步。 可以使用以下对象共享机制：

* 如果 CreateMutex 的 lpMutexAttributes 参数启用继承，则由 CreateProcess 函数创建的子进程可以继承互斥对象的句柄。 此机制适用于命名和未命名的互斥体。
* 进程可以在调用 DuplicateHandle 函数时指定互斥对象的句柄，以创建可供另一个进程使用的重复句柄。 此机制适用于命名和未命名的互斥体。
* 进程可以在对 [OpenMutex](./nf-synchapi-openmutexw.md) 或 CreateMutex 的调用中指定命名互斥锁，以检索互斥锁对象的句柄。

使用 CloseHandle 函数关闭句柄。 当进程终止时，系统会自动关闭句柄。 互斥对象在其最后一个句柄被关闭时被销毁。

synchapi.h 头文件将 CreateMutex 定义为别名，它根据 UNICODE 预处理器常量的定义自动选择此函数的 ANSI 或 Unicode 版本。 将编码中性别名与非编码中性的代码混合使用可能会导致不匹配，从而导致编译或运行时错误。 有关详细信息，请参阅函数原型的约定。

### 例子

```c++
#include <windows.h>
#include <stdio.h>

#define THREADCOUNT 2

HANDLE ghMutex;

DWORD WINAPI WriteToDatabase( LPVOID );

int main( void )
{
    HANDLE aThread[THREADCOUNT];
    DWORD ThreadID;
    int i;

    // Create a mutex with no initial owner

    ghMutex = CreateMutex(
        NULL,              // default security attributes
        FALSE,             // initially not owned
        NULL);             // unnamed mutex

    if (ghMutex == NULL)
    {
        printf("CreateMutex error: %d\n", GetLastError());
        return 1;
    }

    // Create worker threads

    for( i=0; i < THREADCOUNT; i++ )
    {
        aThread[i] = CreateThread(
                     NULL,       // default security attributes
                     0,          // default stack size
                     (LPTHREAD_START_ROUTINE) WriteToDatabase,
                     NULL,       // no thread function arguments
                     0,          // default creation flags
                     &ThreadID); // receive thread identifier

        if( aThread[i] == NULL )
        {
            printf("CreateThread error: %d\n", GetLastError());
            return 1;
        }
    }

    // Wait for all threads to terminate

    WaitForMultipleObjects(THREADCOUNT, aThread, TRUE, INFINITE);

    // Close thread and mutex handles

    for( i=0; i < THREADCOUNT; i++ )
        CloseHandle(aThread[i]);

    CloseHandle(ghMutex);

    return 0;
}

DWORD WINAPI WriteToDatabase( LPVOID lpParam )
{
    // lpParam not used in this example
    UNREFERENCED_PARAMETER(lpParam);

    DWORD dwCount=0, dwWaitResult;

    // Request ownership of mutex.

    while( dwCount < 20 )
    {
        dwWaitResult = WaitForSingleObject(
            ghMutex,    // handle to mutex
            INFINITE);  // no time-out interval

        switch (dwWaitResult)
        {
            // The thread got ownership of the mutex
            case WAIT_OBJECT_0:
                __try {
                    // TODO: Write to the database
                    printf("Thread %d writing to database...\n",
                            GetCurrentThreadId());
                    dwCount++;
                }

                __finally {
                    // Release ownership of the mutex object
                    if (! ReleaseMutex(ghMutex))
                    {
                        // Handle error.
                    }
                }
                break;

            // The thread got ownership of an abandoned mutex
            // The database is in an indeterminate state
            case WAIT_ABANDONED:
                return FALSE;
        }
    }
    return TRUE;
}
```

## [PlaySound](https://docs.microsoft.com/en-us/previous-versions//ms712879(v=vs.85)?redirectedfrom=MSDN)

PlaySound 函数播放由给定文件名、资源或系统事件指定的声音。（系统事件可能与注册表或 WIN.INI 文件中的声音相关联。）

```c++
BOOL PlaySound(
  LPCTSTR pszSound,
  HMODULE hmod,
  DWORD fdwSound
);
```

### 参数

#### pszSound

指定要播放的声音的字符串。包括空终止符在内的最大长度为 256 个字符。如果此参数为 NULL，则停止当前播放的任何波形声音。要停止非波形声音，请在fdwSound参数中指定 SND_PURGE。

fdwSound中的三个标志（SND_ALIAS、SND_FILENAME 和 SND_RESOURCE）确定名称是否被解释为系统事件、文件名或资源标识符的别名。如果没有指定这些标志，PlaySound将在注册表或 WIN.INI 文件中搜索与指定声音名称的关联。如果找到关联，则播放声音事件。如果在注册表中未找到关联，则该名称被解释为文件名。

#### hmod

包含要加载的资源的可执行文件的句柄。除非在 fdwSound 中指定了SND_RESOURCE，否则此参数必须为 NULL 。

# fdwSound

用于播放声音的标志。定义了以下值。

* SND_APPLICATION: pszSound参数是注册表中特定于应用程序的别名。您可以将此标志与 SND_ALIAS 或 SND_ALIAS_ID 标志结合使用，以指定应用程序定义的声音别名。
* SND_ALIAS: pszSound参数是注册表或 WIN.INI 文件中的系统事件别名。不要与 SND_FILENAME 或 SND_RESOURCE 一起使用。
* SND_ALIAS_ID: pszSound参数是系统事件别名的预定义标识符。见备注。
* SND_ASYNC: 声音是异步播放的，PlaySound在声音开始后立即返回。要终止异步播放的波形声音，请调用PlaySound并将pszSound设置为 NULL。
* SND_FILENAME: pszSound参数是一个文件名。如果找不到文件，则函数播放默认声音，除非设置了 SND_NODEFAULT 标志。
* SND_LOOP: 声音重复播放，直到再次调用PlaySound并将pszSound参数设置为 NULL。如果设置了此标志，您还必须设置 SND_ASYNC 标志。
* SND_MEMORY: pszSound参数指向加载到内存中的声音 。
* SND_NODEFAULT: 不使用默认声音事件。如果找不到声音，PlaySound会静默返回，不播放默认声音。
* SND_NOSTOP： 指定的声音事件将让给另一个已经在播放的声音事件。如果由于生成该声音所需的资源正忙于播放另一个声音而无法播放声音，则该函数将立即返回 FALSE 而不播放请求的声音。如果未指定此标志，PlaySound会尝试停止当前播放的声音，以便可以使用设备播放新声音。
* SND_NOWAIT： 如果驱动忙，请立即返回，不要播放声音。
* SND_PURGE： 不支持。
* SND_RESOURCE： pszSound参数是一个资源标识符；hmod必须标识包含资源的实例。
* SND_SENTRY： 需要 Windows Vista 或更高版本。如果设置了此标志，则该函数会在播放声音时触发 SoundSentry 事件。SoundSentry 是一种辅助功能，它使计算机在播放声音时显示视觉提示。如果用户没有启用 SoundSentry，则不会显示视觉提示。
* SND_SYNC： 声音同步播放，声音事件完成后PlaySound返回。这是默认行为。
* SND_SYSTEM： 需要 Windows Vista 或更高版本。如果设置了此标志，则声音将分配给系统通知声音的音频会话。系统音量控制程序 (SndVol) 显示控制系统通知声音的音量滑块。设置此标志会将声音置于该音量滑块的控制之下。如果未设置此标志，则声音将分配给应用程序进程的默认音频会话。

### 返回值

如果成功则返回 TRUE，否则返回 FALSE。



#### fdwSound

[WakeConditionVariable function (synchapi.h)](https://docs.microsoft.com/zh-cn/windows/win32/api/synchapi/nf-synchapi-wakeconditionvariable)

[WakeAllConditionVariable function (synchapi.h)](https://docs.microsoft.com/zh-cn/windows/win32/api/synchapi/nf-synchapi-wakeallconditionvariable)

[SleepConditionVariableSRW function (synchapi.h)](https://docs.microsoft.com/zh-cn/windows/win32/api/synchapi/nf-synchapi-sleepconditionvariablesrw)

[SleepConditionVariableCS function (synchapi.h)](https://docs.microsoft.com/zh-cn/windows/win32/api/synchapi/nf-synchapi-sleepconditionvariablecs)


[Using One-Time Initialization](https://docs.microsoft.com/en-us/windows/win32/sync/using-one-time-initialization)
