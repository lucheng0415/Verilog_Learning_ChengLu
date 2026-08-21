# NVMe 协议速查与面试题

面向 SSD / UFS 固件测试岗位的 NVMe 协议学习笔记。按面试官提问的自然顺序编排，每个知识点后面跟着对应的考法和常见的坑。

内容依据 NVM Express 公开规范，以及第三方实验室与厂商的公开技术文章整理。具体字段位定义以所对标的规范版本原文为准 —— 不同版本之间存在差异，尤其是 2.0 拆分前后。

---

## 目录

1. [为什么需要 NVMe](#1-为什么需要-nvme)
2. [架构三要素](#2-架构三要素)
3. [队列与命令生命周期](#3-队列与命令生命周期)
4. [命令与完成条目格式](#4-命令与完成条目格式)
5. [PRP 与 SGL](#5-prp-与-sgl)
6. [寄存器与初始化流程](#6-寄存器与初始化流程)
7. [Admin 命令集](#7-admin-命令集)
8. [NVM 命令集](#8-nvm-命令集)
9. [Log Page 与 SMART](#9-log-page-与-smart)
10. [电源管理](#10-电源管理)
11. [数据保护与原子性](#11-数据保护与原子性)
12. [版本演进](#12-版本演进)
13. [协议合规测试](#13-协议合规测试)
14. [面试题集](#14-面试题集)
15. [学习路径与资源](#15-学习路径与资源)

---

## 1. 为什么需要 NVMe

几乎所有 NVMe 面试的第一题都是它和 AHCI 的对比。看似简单，但答得深浅直接决定面试官对你的定位。

AHCI/SATA 是为机械硬盘设计的协议。机械盘的瓶颈是磁头寻道，机械延迟在毫秒级，协议层再怎么优化也没意义，所以 AHCI 只有 **1 个命令队列、深度 32**，而且是半双工。把这套协议套在闪存上，等于给跑车装自行车刹车 —— 闪存本身是多通道、多 die、天然可并行的，AHCI 却只能串行地喂命令。

NVMe 的设计前提反过来：假设介质本身足够快，瓶颈就转移到软件栈和协议开销上。于是它做了三件事 —— 直接挂在 PCIe 上省掉 HBA 转换层、把队列数量和深度提升几个数量级、精简指令集只保留闪存真正需要的操作。

| 维度 | AHCI / SATA | NVMe |
|---|---|---|
| 队列数 | 1 | 最多 65,535 个 I/O 队列 |
| 队列深度 | 32 | 每队列最多 65,536 |
| 总线 | SATA（经 HBA 转换） | PCIe 直连 CPU |
| 未缓存寄存器读 | 每条命令 4 次 | 0 次 |
| MSI-X 与中断聚合 | 不支持 | 支持 |
| 并行性 | 单线程串行 | 每 CPU core 可独占队列对 |

> **答题加分点** — 多队列的真正价值不只是"更深"，而是**每个 CPU core 可以独占一对 SQ/CQ**，从而彻底消除多核之间抢锁的开销。这是 NVMe 能把 IOPS 做到百万级的结构性原因。只答"队列多、速度快"是背书，答到无锁并行才是理解。

---

## 2. 架构三要素

Controller、Namespace、Queue Pair —— 这三个概念的层级关系搞混，后面所有命令的作用域都会讲错。

| 概念 | 说明 |
|---|---|
| **Controller** | PCIe 设备的功能实体，一个 SSD 上可以有多个（SR-IOV 虚拟化、双端口企业盘）。Host 通过它下发所有命令。`Identify Controller` 返回它的能力集。 |
| **Namespace** | 一组逻辑块（LB）的集合，是格式化和访问的基本单位，用 `NSID` 标识。一个 Controller 可挂多个 Namespace；企业场景下多个 Controller 可共享同一个 Namespace（shared namespace）。 |
| **Logical Block** | 最小读写单元，常见 512B 或 4KB，用 `LBA` 寻址。LBA Format 在 Identify Namespace 里定义，包含数据大小和元数据大小。 |
| **Queue Pair** | 一个 SQ 加一个 CQ。**不是一一对应** —— 多个 SQ 可以共享一个 CQ，这是常考的细节。 |

### Admin 队列 vs I/O 队列

- **Admin Queue 有且只有一对**，QID 固定为 0，最大深度 4,096，在初始化时通过 `AQA` / `ASQ` / `ACQ` 寄存器配置，用来跑管理类命令。
- **I/O Queue 可以有很多对**，QID 用 16 bit 标识，最大深度 65,536，由 Admin 命令 `Create I/O CQ` / `Create I/O SQ` 动态创建。注意顺序：**必须先建 CQ 再建 SQ**，因为建 SQ 时要指定它关联的 CQ。
- 队列最小深度是 2。判满的规则是**头指针等于尾指针加一**，也就是永远浪费一个槽位来区分空和满。

---

## 3. 队列与命令生命周期

"描述一条 Read 命令从主机到设备的完整路径" —— 这是 NVMe 面试的核心题，能不能顺畅讲完这八步，直接暴露你是真懂还是背过。

关键前提：**SQ 和 CQ 都在 Host 内存里**，Doorbell 寄存器在 SSD 控制器里。所以命令是控制器主动 DMA 过来取的，不是主机推过去的。

| # | 主体 | 动作 |
|---|---|---|
| 1 | Host | 把 64 字节的命令（SQE）写入 Submission Queue 尾部，更新自己维护的 SQ Tail |
| 2 | Host → 控制器 | 写 `SQ Tail Doorbell` 寄存器，告知"有新活了" |
| 3 | 控制器 | 通过 DMA 从 Host 内存取回命令，可能一次取多条 |
| 4 | 控制器 | 按仲裁策略（RR / WRR / 厂商自定义）选出命令，解析 Opcode 与参数 |
| 5 | 控制器 | 执行命令。读操作从 NAND 取数据，按 PRP/SGL 指定地址 DMA 写回 Host 内存 |
| 6 | 控制器 | 把 16 字节完成条目（CQE）写入 CQ，其中带回 SQ Head，隐式告知可回收的 SQ 槽位 |
| 7 | 控制器 → Host | 触发 MSI-X 中断（可被中断聚合策略延迟或合并） |
| 8 | Host | 处理完成条目，写 `CQ Head Doorbell` 释放 CQ 槽位。**这一步不能省** |

### Phase Tag：Host 怎么知道 CQE 是新的

CQE 里有一个 **P（Phase）bit**。控制器每写满一轮 CQ 并回卷时，就把写入的 P bit 取反。Host 只要比对 CQE 的 P bit 和自己记录的期望相位，就能判断这条完成项是本轮新写的还是上一轮的残留 —— 这样**不需要额外读寄存器**就能轮询完成状态，正是 SPDK 这类用户态轮询驱动能做到极低延迟的基础。

> **常见追问** — "Doorbell 寄存器能读吗？" **不能**。Doorbell 是只写的。Host 必须自己在内存里维护头尾指针的影子副本；CQ 里回传的 SQ Head 就是控制器告知消费进度的唯一途径。答错这题会显得只看过框图没碰过实现。

### 仲裁机制

- **Round Robin** — 所有 I/O SQ 平等轮转，默认策略。
- **Weighted Round Robin with Urgent Priority** — 分 Urgent 加 High / Medium / Low 三档带权重，用于区分延迟敏感和吞吐型负载。
- **Vendor Specific** — 厂商自定义。
- Admin SQ 永远享有最高优先级，不参与 I/O 队列的仲裁。

---

## 4. 命令与完成条目格式

做协议测试要逐字段比对返回值，所以 SQE 和 CQE 的结构必须能默写出来。

### Submission Queue Entry — 64 字节

| 字段 | 位置 | 含义 |
|---|---|---|
| OPC | CDW0 [7:0] | Opcode，标识具体命令 |
| FUSE | CDW0 [9:8] | 融合操作标记（Compare and Write 用） |
| PSDT | CDW0 [15:14] | 选择用 PRP 还是 SGL |
| CID | CDW0 [31:16] | 命令标识符，完成时原样返回，用来配对 |
| NSID | CDW1 | 目标 Namespace；`FFFFFFFFh` 表示广播到全部 |
| MPTR | CDW4–5 | 元数据指针 |
| DPTR | CDW6–9 | 数据指针，即 PRP1/PRP2 或 SGL1 |
| CDW10–15 | CDW10–15 | 命令专属参数（读写命令里放 SLBA 和 NLB） |

### Completion Queue Entry — 16 字节

| 字段 | 位置 | 含义 |
|---|---|---|
| DW0 | 命令专属 | 部分命令的返回值 |
| SQHD | DW2 [15:0] | SQ Head 指针，告知 Host 可回收的槽位 |
| SQID | DW2 [31:16] | 该命令来自哪个 SQ |
| CID | DW3 [15:0] | 与 SQE 中的 CID 对应 |
| P | DW3 [16] | Phase Tag，每轮回卷取反 |
| SC | DW3 [24:17] | Status Code，具体错误码 |
| SCT | DW3 [27:25] | Status Code Type，错误大类 |
| M / DNR | DW3 [30:31] | More（还有更多错误信息）/ Do Not Retry |

### 状态码分类（SCT）

- `0h` **Generic Command Status** — 通用错误，如 Invalid Opcode、Invalid Field、Data Transfer Error、Command Abort。
- `1h` **Command Specific Status** — 命令专属错误，如 Invalid Queue Identifier、Invalid Format。
- `2h` **Media and Data Integrity Errors** — 介质与数据完整性错误，如 Unrecovered Read Error、Guard Check Error。**做失效分析时这类最值得关注**，意味着问题出在 NAND 或数据保护链路上。
- `3h` **Path Related Status** — 1.4 引入，多路径与 Fabrics 场景的路径错误。

---

## 5. PRP 与 SGL

这题是分水岭 —— 能讲清 PRP2 的双重身份，基本可以确认你真读过 spec。

**PRP（Physical Region Page）** 是 64 位物理地址指针，描述 Host 内存里的数据缓冲区。规则很死：除了第一个 PRP 可以有页内偏移（且偏移必须 4 字节对齐），**后续所有 PRP 都必须页对齐**，每个 PRP 只能描述一个内存页。

命令里有 PRP1 和 PRP2 两个入口，PRP2 的含义随传输长度变化，这正是考点：

| 传输长度 | PRP2 的含义 |
|---|---|
| 数据 ≤ 1 页 | PRP1 指向数据，PRP2 不使用 |
| 数据 ≤ 2 页 | PRP1 和 PRP2 各**直接指向一个数据页** |
| 数据 > 2 页 | PRP2 改为**指向一个 PRP List**（一页装满 PRP 条目的表）。若一页 List 不够，List 最后一项再指向下一个 PRP List，形成链式结构 |

**SGL（Scatter Gather List）** 则灵活得多：由 Segment 和 Descriptor 组成，每个描述符可以描述**任意长度**的连续物理空间，不受页边界约束。代价是解析开销更大。PCIe 场景下大多用 PRP，而 **NVMe over Fabrics 强制要求支持 SGL** —— 因为网络传输的数据块本来就不按内存页切分。

> **测试视角** — PRP 的对齐规则是构造边界用例的富矿：非对齐偏移、跨页边界的传输、恰好等于 2 页 vs 略超 2 页（触发 PRP List 切换）、PRP List 恰好填满一页（触发链式跳转）。这些边界正是固件容易出 bug 的地方，面试时能主动说出这套用例设计思路会很加分。

---

## 6. 寄存器与初始化流程

盘认不出来、初始化卡住，是产品验证阶段的高频故障，排查全靠这几个寄存器。

| 寄存器 | 说明 |
|---|---|
| **CAP** | Controller Capabilities，只读。包含最大队列深度 MQES、Doorbell 步长 DSTRD、支持的命令集 CSS、超时时间 TO、最小/最大页大小 MPSMIN/MPSMAX |
| **CC** | Controller Configuration，可写。设置页大小 MPS、仲裁策略 AMS、SQ/CQ 条目大小 IOSQES/IOCQES，以及最关键的使能位 `CC.EN` |
| **CSTS** | Controller Status。`CSTS.RDY` 表示控制器就绪，`CSTS.CFS` 表示致命错误 |
| **AQA / ASQ / ACQ** | Admin 队列的深度属性、SQ 基地址、CQ 基地址。必须在置 `CC.EN` 之前配好 |
| **Doorbell** | 从偏移 `1000h` 开始，按 QID 依次排布，步长由 CAP.DSTRD 决定。**只写不可读** |

### 初始化顺序

1. 确认 `CSTS.RDY` 为 0，控制器处于复位态
2. 配置 `AQA`（Admin 队列深度）、`ASQ` 与 `ACQ`（基地址）
3. 配置 `CC`：页大小、仲裁策略、命令集、条目大小
4. 置 `CC.EN = 1`，轮询等待 `CSTS.RDY` 变 1，超时上限由 CAP.TO 给出
5. 发 `Identify` 命令获取控制器与 Namespace 信息
6. 用 `Set Features`（Feature ID 07h）申请 I/O 队列数量
7. 创建 I/O CQ，再创建 I/O SQ —— **顺序不能反**

> **高频故障场景** — `CC.EN` 置 1 后 `CSTS.RDY` 迟迟不变 1，是产品验证里最常见的 bring-up 故障之一。排查路径：先确认 PCIe 链路已训练到目标速率和位宽、BAR 空间映射正确，再看 Admin 队列基地址是否真的物理连续且对齐，最后才怀疑固件。这条排查链路和硅后 bring-up 的思路完全一致。

---

## 7. Admin 命令集

协议合规测试的主战场 —— 业界标准测试套件里绝大多数测试项都在打这些命令。

| 命令 | 用途 | 测试要点 |
|---|---|---|
| **Identify** | 获取控制器 / Namespace / 列表信息，由 CNS 字段选择返回类型 | CNS=01h 控制器、00h Namespace、02h NS 列表、03h NS 描述符；校验保留字段是否为 0 |
| **Get / Set Features** | 查询和配置控制器行为 | Feature ID 01h 仲裁、02h 电源管理、07h 队列数、08h 中断聚合、0Ch APST；测 Save 位与掉电保持 |
| **Get Log Page** | 读取各类日志 | LID 01h 错误日志、02h SMART、03h 固件槽位、04h 变更 NS 列表 |
| **Create/Delete I/O CQ** | 创建、删除完成队列 | 先建 CQ 后建 SQ；删除顺序相反；非法 QID 要正确报错 |
| **Create/Delete I/O SQ** | 创建、删除提交队列 | 关联到不存在的 CQ 必须返回 Invalid Queue Identifier |
| **Abort** | 中止指定命令 | ACL 限制并发中止数；中止不存在的 CID 的行为 |
| **Async Event Request** | 异步事件上报 | 温度越限、可用备用空间不足、介质错误的上报时机 |
| **Firmware Download / Commit** | 固件下载与激活 | 多槽位管理、激活方式、回滚、下载中断电 |
| **Format NVM** | 格式化 Namespace | 切换 LBA Format、Secure Erase 设置、格式化中断电 |
| **Device Self-test** | 设备自检 | short / extended 两种；自检中下发 I/O 的行为 |
| **Sanitize** | 安全擦除 | Block / Crypto / Overwrite 三种；过程中掉电必须能续做 |
| **Namespace Management** | 创建、删除 Namespace | 容量分配、附加/分离到控制器 |

---

## 8. NVM 命令集

数据面命令数量不多，但每一条背后都牵着固件算法。

| 命令 | 说明 |
|---|---|
| **Read / Write** | 核心读写。CDW10–11 放起始 LBA（SLBA），CDW12 低位放块数（`NLB`，**0-based，写 0 表示 1 个块** —— 经典边界坑） |
| **Flush** | 把 volatile write cache 刷到非易失介质。**掉电保护测试必测**：Flush 返回成功之后断电，数据必须仍在 |
| **Compare** | 比较介质数据与 Host 数据，不一致则报错。可与 Write 组成 Fused 操作实现原子的 compare-and-write |
| **Write Zeroes** | 写零而无需真正传输数据，省带宽 |
| **Write Uncorrectable** | 人为把某些 LBA 标记为不可纠正 —— **测试工程师的利器**，用来构造读错误场景验证上层容错 |
| **Dataset Management** | 即 TRIM / Deallocate，告诉 SSD 哪些 LBA 已失效。直接影响 GC 效率和写放大，是性能测试必须考虑的变量 |
| **Verify** | 1.4 引入。只校验数据可读性而不传回 Host，用于后台巡检 |
| **Copy** | 2.0 引入。盘内直接搬移数据，不经过 Host 内存 |

---

## 9. Log Page 与 SMART

SMART（Log ID `02h`）是耐久性测试和客退分析的主要数据来源，字段含义要能张口就来。

| 字段 | 含义与测试用途 |
|---|---|
| **Critical Warning** | 逐 bit 告警：bit0 备用空间低于阈值、bit1 温度越限、bit2 介质可靠性下降、bit3 只读模式、bit4 易失内存备份失效 |
| **Composite Temperature** | 整盘温度，**单位是开尔文**，减 273 才是摄氏度。另有 8 个独立温感 |
| **Available Spare** | 剩余备用块百分比，跌破 Threshold 触发告警 |
| **Percentage Used** | 寿命消耗估计，**可以超过 100%**，超了不代表立即失效 |
| **Data Units Read/Written** | 累计读写量，单位是 1000 个 512 字节块。**算写放大的分子分母就靠它** |
| **Host Read/Write Commands** | 主机命令计数，可反推平均 IO 大小 |
| **Controller Busy Time** | 控制器繁忙时长（分钟），用于估算真实负载 |
| **Power Cycles** | 上电次数 |
| **Unsafe Shutdowns** | 异常掉电次数 —— **掉电测试后必查此项**，确认测试真的触发了异常掉电路径 |
| **Media and Data Integrity Errors** | 介质与数据完整性错误累计，客退分析的关键指标 |
| **Number of Error Information Log Entries** | 错误日志条目数，配合 Log ID 01h 取详细信息 |

> **实战问法** — "客户反馈盘变慢了，你拿到盘之后先看什么？" 先读 SMART：看 Percentage Used 判断是否接近寿命、看 Available Spare 是否大量掉备用块、看温度和 Thermal Throttling 计数判断是否在降频、看 Unsafe Shutdowns 是否异常多。**先用数据缩小范围再上分析仪**，这个顺序体现的是方法论。

---

## 10. 电源管理

JD 里"功耗优化验证"对应的就是这块，笔记本和移动场景尤其看重。

NVMe 定义了多个 Power State，典型是 `PS0` 到 `PS4`。PS0 到 PS2 通常是 operational state（可以处理 I/O，功耗和性能递减），PS3、PS4 是 **non-operational state**（不能处理 I/O，必须先唤醒），功耗可以低到毫瓦级。每个状态的最大功耗、进入延迟、退出延迟都在 Identify Controller 数据结构里声明。

**APST（Autonomous Power State Transition）** 让盘在空闲一段时间后**自主**降到更省电的状态，不需要 Host 干预，通过 Feature ID `0Ch` 配置每个状态的空闲超时（ITPT）和目标状态（ITPS）。这是笔记本续航的关键，但也是**臭名昭著的故障源** —— Linux 上有大量 NVMe 盘因为 APST 深度睡眠后唤醒失败导致 IO hang 甚至掉盘的案例，很多发行版为此维护了问题设备黑名单。

> **功耗测试怎么设计** — 逐个状态验证：进入延迟和退出延迟是否符合声明值、各状态实测功耗是否在标称范围内、APST 超时是否准确触发、**从最深的 non-operational 状态唤醒后第一条 I/O 的延迟**（用户能感知到的卡顿来源）、以及反复快速进出低功耗态的稳定性。测量要用真实功耗仪配合协议分析仪打时间戳，把功耗曲线和命令时序对齐看。

---

## 11. 数据保护与原子性

企业级盘的必考项，也是"数据可靠性"这条职责的技术落点。

### 端到端数据保护（PI）

在每个逻辑块后附加 8 字节保护信息，包含三部分：**Guard Tag**（数据的 CRC16）、**Application Tag**（应用自定义）、**Reference Tag**（与 LBA 关联，防止数据写错位置）。分三种类型：

- **Type 1** — Reference Tag 必须等于 LBA 低 32 位，防错位能力最强
- **Type 2** — Reference Tag 由 Host 指定初值，允许更灵活的映射
- **Type 3** — 不校验 Reference Tag

元数据的组织方式也有两种：与数据交织存放（DIF 风格），或分离到独立缓冲区（DIX 风格，对应命令里的 MPTR）。测试时要覆盖故意注入 Guard 错误、Reference Tag 错误后固件是否正确报出对应的 Media and Data Integrity Error。

### 写原子性

Identify Controller 里声明了 `AWUN`（Atomic Write Unit Normal）和 `AWUPF`（Atomic Write Unit Power Fail）。前者是正常运行时保证原子的写入大小，后者是**掉电情况下**仍保证原子的大小。数据库这类应用严重依赖 AWUPF —— 如果一次写被掉电撕裂成"半新半旧"，上层的日志机制会直接失效。掉电测试里验证 AWUPF 是重头戏。

---

## 12. 版本演进

面试官常用这题探你是不是还在跟进技术，别只停留在 1.3。

| 版本 | 关键内容 |
|---|---|
| **1.3** | Device Self-test、Sanitize、Directives、虚拟化增强。国内大量中文资料停在这一版 |
| **1.4** | Persistent Memory Region、Verify 命令、IO Determinism（NVM Set）、Rebuild Assist |
| **2.0** | **架构级重组**：拆成 Base Specification、多个 Command Set Specification（NVM / ZNS / Key-Value）、以及 Transport Specification（PCIe / RDMA / TCP）。新命令集可独立演进而不动基础规范。同时正式纳入 **ZNS（Zoned Namespace）** |
| **2.3** | 面向 AI、云计算与企业存储的多项性能与管理增强 |
| **2.4** | 2026 年发布的最新版本，强化安全性与虚拟化管理能力 |

**ZNS 值得单独准备一句**：把 Namespace 划分成必须顺序写的 Zone，把垃圾回收的责任部分交给 Host，从而大幅降低写放大和 over-provisioning 需求。面试时能主动提到 ZNS 和它对 FTL 的简化作用，会显得你在关注行业方向而不只是在背当前产品。

---

## 13. 协议合规测试

### 合规测试打哪些命令

业界的 NVMe 一致性测试套件覆盖的典型测试项包括：`Identify`、`Get Log`、`Get/Set Feature`、`Create/Delete IO Queue`、`Abort`、`Async Event Request`、`Device Self Test`、`Sanitize`、`Controller Capabilities`、`Compare`、`Flush`、`Read/Write` 等，逐条验证控制器的返回值是否符合规范定义。

### 回归测试的四个经典项

- **Power Cycle with Random commands** — 随机命令流中随机断电
- **Power Cycle with Data compare** — 断电后逐块比对数据一致性
- **MD5 with power cycle** — 用校验和验证大批量数据在反复掉电后的完整性
- **JEDEC Workload（Client / Enterprise）** — 用行业标准负载模型跑耐久性

这组测试的共同目标是：**验证非预期断电时 SSD 能否正常启动掉电保护机制并保证数据正确**。

### 该知道的工具与组织

| 工具 / 组织 | 说明 |
|---|---|
| **UNH-IOL** | 新罕布什尔大学互操作实验室，NVMe 一致性测试与 Integrator's List 的权威机构 |
| **Ulink DriveMaster** | 业界常用的协议合规测试工具，第三方实验室在用 |
| **nvme-cli** | Linux 下的开源工具，学协议和日常验证的首选，可直接对真盘发 Identify、Get Log Page 等命令看返回结构 |
| **FIO** | 性能基准测试事实标准。注意**必须先预处理到稳态再测**，否则测到的是 SLC cache 的假象 |
| **协议分析仪** | Teledyne LeCroy 等，抓 PCIe 总线上的 NVMe 命令时序，定位是主机侧还是设备侧问题 |
| **QEMU NVMe 模拟设备** | 没有真实硬件时构造异常场景的实验环境 |

---

## 14. 面试题集

按由浅入深三档排列。每题给出答题骨架，以及答歪了会踩的坑。

### 基础层 · 筛人用，答不上直接结束

**Q1. NVMe 相比 AHCI/SATA 的优势是什么？**

> **要点** — 队列数与深度提升数个量级（1×32 → 64K×64K）；PCIe 直连省掉 HBA 转换；精简指令集；每条命令 0 次未缓存寄存器读；支持 MSI-X 与中断聚合。
>
> **坑** — 只答"更快"。要把"为什么快"归因到**每核独占队列对消除锁竞争**这个结构性原因上。

**Q2. 描述一条 Read 命令从主机到设备的完整路径。**

> **要点** — 写 SQE 入 SQ → 写 SQ Tail Doorbell → 控制器 DMA 取命令 → 仲裁并执行 → 数据按 PRP/SGL DMA 回 Host → 写 CQE 入 CQ（含 SQ Head）→ 触发 MSI-X → Host 处理并写 CQ Head Doorbell。
>
> **坑** — 漏掉最后一步写 CQ Doorbell；或说反方向 —— 命令是控制器**主动 DMA 取**的，不是主机推过去的。

**Q3. Admin 队列和 I/O 队列有什么区别？**

> **要点** — Admin 有且仅有一对，QID=0，最大深度 4096，靠寄存器配置，优先级最高不参与仲裁；I/O 队列可多对，最大深度 64K，由 Admin 命令动态创建，先建 CQ 再建 SQ。
>
> **坑** — 说 SQ 和 CQ 必须一一对应 —— 实际上多个 SQ 可共享一个 CQ。

**Q4. SQE 和 CQE 分别多大？CQE 里有哪些关键字段？**

> **要点** — SQE 64 字节，CQE 16 字节。CQE 关键字段：SQHD（回收 SQ 槽位）、SQID、CID（与命令配对）、P（Phase Tag）、SC/SCT（状态码及大类）、DNR。

### 进阶层 · 区分"看过 spec"和"没看过"

**Q5. PRP 和 SGL 有什么区别？PRP2 在什么情况下指向 PRP List？**

> **要点** — PRP 只能描述页大小的块，除首个外必须页对齐；数据 ≤1 页只用 PRP1，≤2 页时 PRP2 直接指向第二页，**>2 页时 PRP2 转为指向 PRP List**，List 满了再链式延伸。SGL 可描述任意长度连续空间，更灵活但解析开销大，NVMe-oF 强制支持。
>
> **坑** — 笼统说"PRP2 指向列表"。**恰好 2 页时 PRP2 是直接指针**，这个分界正是考点。

**Q6. Host 怎么判断 CQ 里的完成条目是新的？**

> **要点** — 靠 Phase Tag（P bit）。控制器每写满一轮回卷就把 P bit 取反，Host 比对期望相位即可判断，**无需读任何寄存器**，这是轮询模式低延迟的基础。

**Q7. Doorbell 寄存器可以读吗？Host 怎么知道 SQ 消费到哪了？**

> **要点** — Doorbell **只写不可读**。Host 自己维护影子指针；控制器通过 CQE 里的 SQHD 字段回传 SQ Head，这是唯一的告知途径。

**Q8. 控制器初始化流程是什么？CC.EN 置 1 后 CSTS.RDY 一直不变 1 怎么排查？**

> **要点** — 流程：确认 RDY=0 → 配 AQA/ASQ/ACQ → 配 CC → 置 CC.EN → 轮询 CSTS.RDY（超时看 CAP.TO）→ Identify → Set Features 申请队列数 → 建 CQ 再建 SQ。排查：PCIe 链路训练状态与速率位宽 → BAR 映射 → Admin 队列内存是否物理连续且对齐 → 最后才怀疑固件。
>
> **机会** — 这题正好可以把硅后 bring-up 的排查方法论接上去，主动讲怎么用示波器/分析仪分层定位。

**Q9. NVMe 有哪几种仲裁机制？**

> **要点** — Round Robin；Weighted Round Robin with Urgent Priority（Urgent + High/Medium/Low 三档权重）；Vendor Specific。Admin SQ 始终最高优先级，不参与 I/O 仲裁。

**Q10. SMART 里你最关注哪几个字段？为什么？**

> **要点** — Percentage Used 判寿命、Available Spare 判坏块消耗、Composite Temperature 加节流计数判降频、Unsafe Shutdowns 验证掉电测试是否真触发、Media and Data Integrity Errors 判介质问题、Data Units Written 算写放大。温度**单位是开尔文**。

### 深水层 · 专家岗真正拉开差距的地方

**Q11. 给你一个新的固件特性，怎么从零设计协议合规测试方案？**

> **要点** — 读 spec 条款和对应 TP 文档 → 逐条提取"必须（shall）"和"可选（may）"的行为 → 拆成正向功能用例、边界值用例、异常/非法输入用例、并发与压力用例 → 设计覆盖率度量（命令覆盖、字段覆盖、状态码覆盖、状态机路径覆盖）→ 定义通过判据 → 纳入回归。**强调用例是从 spec 条款反推出来的**，不是拍脑袋列的。

**Q12. 白盒和灰盒测试在固件测试里具体怎么落地？**

> **要点** — 白盒：拿到固件源码/内部状态/调试日志，针对特定算法分支（GC 触发路径、映射表更新、坏块处理）设计用例，用语句/分支/条件/路径覆盖率度量，能直接看到内部变量验证算法正确性。灰盒：不完全掌握实现，但知道架构和状态机，通过命令组合、边界值、并发压力去覆盖状态转换路径，结合日志和 SMART 反推内部行为。
>
> **坑** — 把灰盒说成"黑盒加一点日志"。灰盒的关键是**基于对内部架构的理解去设计用例**，而不只是多看了点输出。

**Q13. 掉电保护（PLP）怎么验证？**

> **要点** — 四类标准回归：Power Cycle with Random commands、Power Cycle with Data compare、MD5 with power cycle、JEDEC Workload。关键设计：断电时机要随机且覆盖关键窗口（映射表刷写中、GC 搬移中、Flush 返回前后、固件升级中）；验证点包括盘能否正常启动、已确认写入的数据是否完整、**AWUPF 范围内的写是否原子未被撕裂**、SMART 的 Unsafe Shutdowns 是否正确累加。硬件上需要可编程掉电治具配合。

**Q14. SSD 用一段时间后写性能下降，从测试角度怎么分析？**

> **要点** — 先区分是否进入稳态：新盘或 TRIM 后的空盘有 SLC cache 和大量空闲块，性能虚高；写满后 GC 开始抢占带宽，写放大上升，性能回落到稳态值。分析路径：确认测试是否做了 preconditioning → 看 SMART 的 Data Units Written 与主机写入量算 WAF → 看是否触发热节流 → 看 over-provisioning 比例和 TRIM 是否生效 → 用分析仪看命令延迟分布是否出现长尾（GC 抢占的典型特征）。
>
> **坑** — 直接说"SLC 缓存用完了"就停。要能讲到 **GC、写放大、稳态、QoS 长尾**这一整条因果链。

**Q15. 抓到一个 IO hang，怎么定位是主机侧、协议层还是固件问题？**

> **要点** — 分层排除：先看 Host 侧驱动日志和 CQE 是否返回（有 CQE 说明命令到过设备）→ 用协议分析仪抓总线，看 SQ Doorbell 是否真的写下去、控制器有没有取命令、有没有回 CQE、CQE 状态码是什么 → 若命令根本没被取走，怀疑 Doorbell 写入或链路 → 若取了不回，怀疑固件卡在某个状态 → 结合 CSTS.CFS 判断是否致命错误 → 检查是否处于低功耗态未唤醒（APST 相关的经典 hang）。
>
> **机会** — 这题是硬件背景的主场。把用示波器/逻辑分析仪做分层定位的经历接上来，讲清"怎么用工具把问题域一层层切掉"。

**Q16. 怎么衡量测试覆盖率是否足够？**

> **要点** — 分层说：代码覆盖率（语句/分支/条件/路径，白盒手段）、需求覆盖率（每条 spec 条款和需求项是否有对应用例）、场景覆盖率（真实应用负载）、状态机路径覆盖。**并明确指出高代码覆盖率不等于测得好** —— 覆盖到了不代表断言充分，还要看缺陷逃逸率和现网问题回溯。

**Q17. 了解 AI 在测试领域的应用吗？**

> **要点** — 用 LLM 从 spec 条款辅助生成测试用例草稿；海量测试日志的异常自动聚类与分类，减少人工看日志；基于历史缺陷数据做回归用例智能筛选，压缩回归时长；失效模式的相似性检索，快速关联历史类似问题。**要给出自己的判断**：AI 适合做用例扩展和日志降噪，但根因定位和判据设计仍然依赖工程师对协议和硬件的理解。

---

## 15. 学习路径与资源

从零到能上手，大约三到六个月。顺序很重要 —— 跳过第一阶段直接啃 spec 会很痛苦。

| 阶段 | 时长 | 内容 |
|---|---|---|
| **一** | 1 个月 | **补底层。** PCIe 分层结构、TLP、MSI-X 中断机制；操作系统存储栈、block layer、DMA。有 SATA/AHCI 背景的话拿来对比着学，理解 NVMe 解决了什么瓶颈 |
| **二** | 1–2 个月 | **精读规范。** 先 Base Specification（队列机制、寄存器、Admin 命令集），再 NVM Command Set Specification。中文资料多停在 1.3，深入必须回到官网英文原文和 TP 文档 |
| **三** | 1 个月 | **动手。** 用 `nvme-cli` 对真盘发 Identify、Get Log Page，把 spec 字段定义和真实返回值对上号；用 QEMU 的 nvme 模拟设备构造非法命令和边界场景 |
| **四** | 1–2 个月 | **测试方法论。** 研究 UNH-IOL 一致性测试套件的组织思路；用 FIO 做性能基准（务必先预处理到稳态）；自己设计一组掉电和边界用例练手。有条件的话摸一次协议分析仪 |

### 核心资源

- [NVM Express 官方规范](https://nvmexpress.org/specifications/) — Base / Command Set / Transport 各版本原文与 TP 文档，唯一权威来源
- [百佳泰：NVMe 协议测试与回归测试](https://www.allion.com.cn/nvme-protocol-regression/) — 第三方实验室视角，列出了合规测试的具体测试项与掉电回归的四类标准测试
- [Memblaze：SMART 信息详解](https://www.memblaze.com/innovate/technical-articles/695.html) — SMART 各字段的定义与解读
- [NVMe 学习笔记：概念解读](https://www.cnblogs.com/FireLife-Cheng/p/16242589.html) — Namespace、队列机制、寄存器、PRP/SGL 的中文入门梳理
- [Memblaze：NVMe 2.0 解读](https://www.memblaze.com/innovate/technical-articles/683.html) — 2.0 规范拆分的背景与 ZNS 等新命令集的意义
- [NVM Express — Wikipedia](https://en.wikipedia.org/wiki/NVM_Express) — 版本演进时间线与特性对照

---

*整理时间：2026 年 8 月*
