---
layout: default
permalink: /Todo.html
---

# TO-DOs和草稿

当前的程序结构

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

---

备忘录：

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
6. `mainLoop`更名为`loopFunction`，与`initFunction`一致。取消"main"字样是为了体现出循环部分并不是必需的。
7. 为适应新的status机制，`loopFunc`和`initFunc`均有wrap，前者在enabled时允许运行，后者在halt时允许运行，并且运行之后将模式调整为disabled
8. `ArcomStd.startNode()`用`pcall`保护运行，当出现错误退出时自动执行`emergencyFunction`，销毁Node并退出。
9. 安全部分包括`safetyProtocal`和`emergencyFunction`。前者负责监控，当除了问题之后设置failed并调用后者。后者负责紧急停车。
10. 大新闻：之前对`rednet.dns`机制的依赖全是错误的。`rednet`只允许每个protocol注册一个hostname。是时候开发真正的`ArcomDNS`了...

---

### Arcomlib的标准化工作 草稿

对象结构

- std对象：提供主程序结构，持有服务器状态

  - 数据成员：

    - 自身属性
      - - [x] string：机器状态 `status` ("halt:主循环停，收场", "enabled：正常工作", "disabled：主循环停，不收场", "failed：故障状态，收场，")
      - - [x] net句柄：网络接口 `netHandle`
    - 持久化相关数据结构
      - - [x] pickler句柄：持久化工具`tablePickler`
      - - [x] table：持久化变量表
    - 函数容器
      - - [x] table：中断向量表`interruptVectorTable`
      - - [x] function：主循环 `mainLoop`
      - - [x] function：初始化函数 `initFunction`
      - - [x] function：安全协议 `safetyProtocol`
      - - [x] function：急停函数`emergencyFunction`
    - 常驻线程：
      - - [ ] 包装后的主循环线程：`loopFunctionWrapper`
      - - [ ] 安全线程：`safetyWatchdog`
      - - [ ] 信息接收线程：`msgListener`

  - 类的接口方法：

    - - [ ] 通用构造器：`new(arcomnet: netHandle)`

  - 对象的接口方法：

    - 注册系列

      - - [ ] 注册主循环：`regLoopFunction(function: loopFunc ) `
      - - [ ] 注册初始化函数：`regInitFunction(function: initFunc )`
      - - [ ] 注册安全协议：`regSafetyProtocal(function: sp )`
      - - [ ] 注册ISR：`regInterruptFunction(function: ISR, string: boundedCmd ) `

    - Node管理界面

      - - [ ] 启动Node：`startNode()`
      - - [ ] 清除Node：`destroyNode()`

    - ISR界面

      - - [ ] 改变状态：`changeStat(string: stat)`

      - - [ ] 引发内中断：`innerInterrupt( targetISR, args )`

        *见思想计划5*

      - - [ ] 读持久化变量：`getPickleVal(string: name)`

      - - [ ] 写持久化变量：`writePickleVal(string: name, anything: val)`

  - 对象的Private方法：

    - - [ ] ISR调用的通用接口`callISR()`

      *包含查找和错误处理的逻辑*



- net对象（lite）：网络通讯，持有主机名

  - 数据成员：

    - 自身属性
      - - [ ] string：主机名`hostName`
      - - [ ] peripheral wrap：Modem句柄`netModem`

  - 类的方法：

    - - [ ] 通用构造器：`new(string: hostname, modemWrap: netModem)`

  - 对象的方法：

    - - [ ] 发送信息：`sendMsg(string: dest, string: targetISR, table: args)`

      *备注：见思想计划4*

    - - [ ] 发送反馈：`sendFeedback(string: stat, string: msg)`

    - - [ ] 接受信息：`pullMsg(number: timeout)`

    - - [ ] 接受反馈：`pullFeedback(number: timeout)`

- net对象（大的）（关系到干网的设计，先放着）：

  ```C
  // TODO
  ```

  ​

---

完成之后再搞自动关火项目，并且把关火项目作为介绍文章中的实例

2. 把pickler并进arcomlib并测试


---

### 文章草稿



1. 什么是中断？ISR又是什么鬼？

   打个比方，你正在兴致勃勃地肝机器，你妈突然喊你去吃饭。这个事件就叫*中断*。再打个比方，你的冶炼厂正在它自己的主循环里不断地进行检测温度、计算是否投料、是否出料的过程，突然你用遥控器叫它关火。而你听到你妈喊你去吃饭，你知道该关了机子（或者，挂机233）然后去餐桌吃饭；而你要想让机器能在你的关火命令下做出你希望的动作，你就得告诉它该干嘛。而你告诉它的“该干嘛”这一坨东西，就叫做*中断服务程序*（Interrupt Service Routines，简称ISR），在这里我们以函数的形式把它写好，注册到ArcomStd里。ArcomStd会在收到一条消息（中断）之后在自己所有的ISR中寻找相应的ISR并调用它。