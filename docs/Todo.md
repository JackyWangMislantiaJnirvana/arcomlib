---
layout: default
permalink: /Todo.html
---

# TO-DOs和草稿

我可能要管这破玩意叫ArcomIoT

![](https://upload.wikimedia.org/wikipedia/commons/a/ab/Internet_of_Things.jpg)

By Wilgengebroed on Flickr - Cropped and sign removed from Internet of things signed by the author.jpg，CC BY 2.0，https://commons.wikimedia.org/w/index.php?curid=32745645

## 第三次迭代

由于搞上一次迭代时在上学，思路总是被打断，做出来的东西乱其八糟。

在给第二次迭代写单元测试的时候突然无法忍受由原型中分割出的两个模块`net`和`std`之间的蜜汁耦合（当初跟CPU同学扯了一晚上这玩意），怒而重新设计。

### Arcomlib需要什么？

1. 机器之间通讯 -> M2M, Net
2. 生产服务器接收通讯，将其解释成请求 -> event pump
3. 生产服务器作为一个控制器所需要的特质： 主循环和安全

### Arcomlib有什么？

注：所有模块都有个`getRunable`方法，这个方法返回适用于递给parallel执行的函数。返回的那个方法直接用闭包访问self。事件源都在这里。

需要监听事件的模块都有个`getHandler`方法，这个方法返回给`EventPump`的事件处理器函数。

接口模块

0. **[搞定!]** 事件泵模块`EventPump`

    从event queue中pull出Arcomlib专属的event，分发到相应的Handler

    处于中心位置。其他模块可以通过`getHandler`获取自己的Handler让自己能监听事件

    ```
    void addHandler(string: name, function: handler)
    void pushEvent(string: name, args...)
    function getRunable()
    ```

1. 通讯模块`M2M`

   保证消息能正确地到达目标主机名，并把收到的消息用`EventPump.pushEvent`推入OS的event queue

   内中断收到这里来了，取消特殊性。local host是有优化的，放心用

   ```
   void sendMsg(string: receiver hostname, message...)
   void sendFeedback(string: stat, string: description)
   threadFunction getRunable()
   ```
   M2M可能要使用自组织网络和动态路由。

   不过初版本只弄最简单的小范围直连

   需要解决的技术栈：

   - 机器之间同步数据？（用来同步网络结构图的知识）
   - 给定图，寻找最短路问题（而且这个图超级大，只能动规，遍历是会死的）
   - 图的增量更新问题

   现在在纠结是用纯节点网络还是要有特殊的网络节点。

   （还是用特殊网络节点/干网方案吧...这个对等网络根本矼不住...）

2. **[搞定!]** 控制器模块`Controller`

   提供循环体和自身状态的记忆。包含了一个`PickleJar`

   ```
   void setLoop(function: loopFunction)
   function getRunable()
   ```

3. **[搞定!] ** 安全模块`Safety`

   ```
   void setEStoper(function: safetyFunction)
   void setWatchdog(function: estoperFunction)
   function getRunable()
   handler getHandler()
   ```

4. **[搞定!]** 持久化模块`PickleJar`

   将数据存储/提取，应付关机掉电的数据丢失

   维护一个缓存表，支持键值对访问，只有初始化和修改的时候才去同步文件（初始化时读，修改时写）。读的时候直接读表，飞快

   弄一个`__index`的特效，可以直接索引对象（`pickle[key]`）来访问value

   （坑很多，不过我已经填上了）

### 客户端程序员需要肝什么？

1. 准备好`M2M`用于通信

2. 准备好`EventPump`用于分发消息到Handler

   在其中注册各个Handler

3. 准备好`Controller`用于创建自动控制器的基础结构

   注册好循环和安全

4. 准备好`Pickler`用于持久化

5. 调用几个上面几个家伙的`getRunable()`，递给`parallel.waitForAll()`

*?弄一个arcomlib文件作为最终用户界面，一键导入?*

## 第二次迭代

思想计划：

1. 结构变更：

   放弃Server和Client的结构（因为要不仅仅是客户端可以给机器发信息，机器与机器之间也可以的思想），全部改成节点（Node），取消客户端的特殊性。客户端只是网络中有一个名为Client的特殊Node。主机名称交给net(both)持有。

2. 通讯(lite)变更：

   放弃Std中的Client内容，Client程序是一个没有Std结构但是有net结构的Node。

   `fireCmd()`给net（或许还得改个名,`sendMsg()`不错）

   反馈机制`sendFeedback()`保留，原反馈频道保留，现在使用的频道：`arcom_msg`（信息，节点对节点），`arcom_fb`（反馈，节点对Client节点）。

   **(Lite，也许Heavy也是这样)除和Client的来往通讯，不准占用广播通道**

   *Note: 为了下一步兼容Open Computers的数字频道名，频道名都是表，利用元表让其在该用数字的OC环境是数字，该用字符串的CC环境是字符串。也许可以利用系统的全局标志符以实现。CC的全局环境里有个`_G._HOST`字符串，包含了CC的版本信息。OC的暂不知道。*

   关于反馈机制的一些变更：反馈信息总是在反馈频道上广播，接收者有二：大显示屏Monitor和Client

3. std中原来`__mainLoopEnabled`状态量的职责交给`std.status`状态量。其中：

> enabled：所有部分正常运行
>
> disabled：仅仅是主循环停止，不执行收场工作，有暂停之意
>
> halt：主循环停止，执行收场操作，如关火
>
> failed：用于出故障和手动急停的情况，主循环停止，执行收场操作（紧急停止）

4. 把用来解析命令字符串的代码从`fireCmd()`拆出，因为只有Client用得上它。
5. std中的`ISRHost`剥离网络功能和搜索ISR的功能，改名`msgListener` ，其工作就是不断循环从net中`pullMsg()`并当有msg的时候调用`callISR()`，由这个行使查找和错误处理的功能。同时内中断不经过原`ISRHost`通道，直接调用`callISR()`

### 对象结构

- std对象：提供主程序结构，持有服务器状态

  - 数据成员：

    - 自身属性
      - string：机器状态 `status` ("halt:主循环停，收场", "enabled：正常工作", "disabled：主循环停，不收场", "failed：故障状态，收场，")
      - net句柄：网络接口 `netHandle`
    - 函数容器
      - table：中断向量表`interruptVectorTable`
      - function：主循环 `mainLoop`
      - function：初始化函数 `initFunction`
      - function：安全协议 `safetyProtocol`
    - 常驻线程：
      - 包装后的主循环线程：`mainLoopWrapper`
      - 安全线程：`safetyWatchdog`
      - 信息接收线程：`msgListener`

  - 类的接口方法：

    - 通用构造器：`new(arcomnet: netHandle)`

  - 对象的接口方法：

    - 注册系列

      - 注册主循环：`regMainLoop(function: mainLoop ) `
      - 注册初始化函数：`regInitFunction(function: initFunc )`
      - 注册安全协议：`regSafetyWatchdog(function: sw )`
      - 注册ISR：`regInterrupt(function: ISR, string: boundedCmd ) `

    - ISR界面

      - 改变状态：`changeStat(string: stat)`

      - 引发内中断：`innerInterrupt( targetISR, args )`

        *见思想计划5*

  - 对象的Private方法：

    - ISR调用的通用接口`callISR()`

      *包含查找和错误处理的逻辑*



- net对象（lite）：网络通讯，持有主机名

  - 数据成员：

    - 自身属性
      - string：主机名`hostName`
      - peripheral wrap：Modem句柄`netModem`

  - 类的方法：

    - 通用构造器：`new(string: hostname, modemWrap: netModem)`

  - 对象的方法：

    - 发送信息：`sendMsg(string: dest, string: targetISR, table: args)`

      *备注：见思想计划4*

    - 发送反馈：`sendFeedback(string: stat, string: msg)`

    - 接受信息：`pullMsg(number: timeout)`

    - 接受反馈：`pullFeedback(number: timeout)`

- net对象（大的）（关系到干网的设计，先放着）：

  ```C
  // TODO
  ```

  ​

---

完成之后再搞自动关火项目，并且把关火项目作为介绍文章中的实例

2. 把pickler并进arcomlib并测试


---

### 文章草稿（需要改

1. 什么是中断？ISR又是什么鬼？

   打个比方，你正在兴致勃勃地肝机器，你妈突然喊你去吃饭。这个事件就叫*中断*。再打个比方，你的冶炼厂正在它自己的主循环里不断地进行检测温度、计算是否投料、是否出料的过程，突然你用遥控器叫它关火。而你听到你妈喊你去吃饭，你知道该关了机子（或者，挂机233）然后去餐桌吃饭；而你要想让机器能在你的关火命令下做出你希望的动作，你就得告诉它该干嘛。而你告诉它的“该干嘛”这一坨东西，就叫做*中断服务程序*（Interrupt Service Routines，简称ISR），在这里我们以函数的形式把它写好，注册到ArcomStd里。ArcomStd会在收到一条消息（中断）之后在自己所有的ISR中寻找相应的ISR并调用它。

## 第一次迭代

原型。（没想到居然跑起来了系列

所有东西都是一坨；只有人机通信；没考虑过掉电的问题

```lua
--------------------------------------------------
-- Server side interface
--------------------------------------------------
	-- Operates the server
function arcomlib.initServer( serverName, modemside ) end
function arcomlib.startServer() end
--------------------------------------------------
	-- Register work logics on server
function arcomlib.regMainLoop( mainLoop ) end
function arcomlib.regInitFunction( initFunc ) end
function arcomlib.regSafetyWatchdog( sw ) end
function arcomlib.regInterrupt( ISR, boundedCmd ) end
--------------------------------------------------
	-- Used by ISRs
function arcomlib.innerInterrupt( targetISR, args ) end
function arcomlib.sendFeedback( stat, msg ) end
----------------------------------------------------------------------------
-- Client side interface
--------------------------------------------------
function arcomlib.initClient() end
function arcomlib.fireCmd( msg ) end
function arcomlib.receiveFeedback() end
--------------------------------------------------
-- Both used
--------------------------------------------------
function arcomlib.clearup() end
```

