# he4o系统

#### he4o是一个螺旋熵减机，是一种通用人工智能（AGI）系统：

1. 机器学习支持：
   - 迁移学习为主
   - 强化学习为辅
2. 知识表征宏微支持：
   - 稀疏码
   - 特征
   - 概念
   - 时序
   - 价值
3. 神经网络支持：动态、模糊、抽具象、组与分、感理性。
4. 支持智能体自主终身动态学习。
5. 无论宏观框架还是微观细节设计,都依从相对与循环转化。
6. 思维控制支持：
   - 出入 (行为 & 感知) //含反馈
   - 认知 (识别 & 学习) //含类比
   - 需求 (任务 & 计划) //含意向
   - 决策 (求解 & 迁移) //含分析
7. 数理：
   - 集合论（迁移）
   - 概率论（强化）
8. 计算：使用最简单的bool运算：`类比`和`评价`。
9. 记忆结构：长时为网（启发式）、短时为树（递归）、瞬时为序（依次）。
10. 编程思想：DOP (面向动态编程：知识由后天演化，先天仅编写控制器和存储结构)。
11. 性能要求：可运行于单机终端（当前是ios设备）。

> 手稿：<https://github.com/jiaxiaogang/HELIX_THEORY>  
> 网站：<http://https://jiaxiaogang.github.io>

[![](https://img.shields.io/badge/%20QQGroup-528053635%20-orange.svg)](tencent://message/?uin=283636001&Site=&Menu=yes)
[![](https://img.shields.io/badge/%20QQ-在线交谈%20-orange.svg)](http://wpa.qq.com/msgrd?v=3&uin=283636001&site=qq&menu=yes)
[![](https://img.shields.io/badge/%20QQ-客户端交谈%20-orange.svg)](tencent://message/?uin=283636001&Site=&Menu=yes)
![](https://img.shields.io/badge/%20Wechat-17636342724%20-orange.svg)
[![License](https://img.shields.io/badge/license-GPL-blue.svg)](LICENSE)

### 1. -------------引言-------------

> 第一梯队:1950年图灵提出"可思考的机器"和"图灵测试",他说:"放眼不远的将来,我们就有很多工作要做";

> 第二梯队:1956达特矛斯会议后，明斯基和麦卡锡等等许多前辈穷其一生心血，虽然符号主义AI在面对不确定性环境下鲁棒性差，但却为AGI奠定了很多基础。

> 第三梯队:随着大数据,云计算等成熟,AI迎来DL、GPT热,但DL、GPT也并非全功能型智能体。

> 综上：近70年以来，人工智能研究跌宕起伏，但与最初设想的AI还相差甚远，he4o旨在实现螺旋熵减机式的通用人工智能系统。

***

### 2. -------------（一）螺旋论-------------

> 　　螺旋论从2017年2月正式开始研究至2018年2月成熟，历时一年。

| 螺旋论：含三大要素：定义、相对和循环，共同呈现螺旋形。 |
| --- |
| https://github.com/jiaxiaogang/HELIX_THEORY#%E7%86%B5%E5%87%8F%E6%9C%BA |

<br>

### 3. -------------（二）螺旋熵减机模型-------------

> 螺旋熵减机理论模型在18年3月成熟，直至今天此模型仍在不断细化中。

| ![](https://github.com/jiaxiaogang/HELIX_THEORY/blob/master/%E6%89%8B%E5%86%99%E7%AC%94%E8%AE%B0/assets/508_%E4%BF%A1%E6%81%AF%E7%86%B5%E5%87%8F%E6%9C%BA202107%E5%8A%A8%E5%9B%BE%E7%89%88.gif?raw=true) |
| --- |
| 1. 此图从内外双向、动静转化、主客角度，三种方式来解读。 |
| 2. 每外一个模块,与内所有模块之和相对循环 (如神经网络与思维,智能体与现实世界) |
| 注: 一切都是从无到有,相对与循环，he4o认为自己活着 `源于循环`; |

<br>

### 5. -------------（三）he4o系统实践-------------

> **V1.0《初版》：**  
> 　　`2017年2月`立项　－ `2018年10月21日`正式落地发布V1.0版本。  
> **V2.0《小鸟生存演示》：**  
> 　　`2018年11月`　－　`至今`　开发完成，测试训练中...

| 架构图 | ![](https://github.com/jiaxiaogang/HELIX_THEORY/raw/master/手写笔记/assets/695_HE架构图V4.png) |
| --- | --- |
| 架构设计 | 由螺旋论展开成螺旋熵减机模型,再由螺旋熵减机模型展开为系统架构 |
| 代码占比 | 内核代码中神经网络占30％,思维控制器占50%,其它（输入、输出等）共占20%; |
| 神经网络 | 神经网络的模型十字总结:`横向宏与微,纵向抽具象`; |
| 思维向性 | 每一种操作方向表示一种思维操作，如：认知、决策、理性、感性。 |
| 思维模块 | `1分2分4分8: 感知(入),识别(认),学习(知),任务(需),计划(求),求解(决),迁移(策),行为(出)` |
| 思维架构 | 思维控制器整体呈现螺旋形运行 |

<br>

### 6. -------------时间线-------------

> ##### 2023.05.25 `至今`
> - 识别准确度提升：`识别二次过滤`

> ##### 2023.05.07 `耗时18天`
> - 回测Solution数据流竞争演化情况：`训练测试稳定的scene演化过程`、`迭代solutionFoRank排名器`

> ##### 2023.05.03 `耗时4天`
> - 梳理TO数据流：`Solution竞争断层: 宽入窄出`、`solutionCanset过滤器`、`solutionScene过滤器`

> ##### 2023.04.20 `耗时12天`
> - Canset迁移性增强回测：`修复canset迁移后支持indexDic等BUG`

> ##### 2023.04.02 `耗时18天`
> - 提升Canset迁移性决策部分：`Canset迁移性增强的决策支持`、`TCScene场景树`、`TCCanset.override算法`、`TCRealact可行性`、`TCTransfer推举和继承算法`、`相应更新SPEFF`

> ##### 2023.03.21 `耗时11天`
> - 提升Canset迁移性认知部分：`外类比支持匹配度共同点`、`构建新Canset优先用场景alg`、`迭代Canst识别&全含判断`、`Canst外类比`、`Canst空概念`、`抽象Canset初始SPEFF`、`Canset识别支持AIFilter`、`回测Canset迁移性`

> ##### 2023.03.09 `耗时12天`
> - 训练：`觅食和防撞训练`、`特征主观恒常性`、`Canset惰性期`、`测得Canset迁移性差问题`

> ##### 2023.02.26 `耗时13天`
> - 优化：`测决策循环连续飞躲`、`反思子任务不求解`、`BUG_行为转任务死循环`、`BUG_静默任务被激活`、`调整过滤器提升识别准确度`、`觅食训练规划:mv进时序(未完成)`、`增加迁移性与识别准确度:废除客观特征`

> ##### 2023.02.14 `耗时12天`
> - 优化：`使取S越来越准`、`识别率低BUG`、`支持AIFilter过滤器`

> ##### 2023.02.04 `耗时10天`
> - 回测：`测试条件满足功能`、`回测项大整理`、`修复R任务的Canset再类比时机与条件判断BUG`

> ##### 2023.01.03 `耗时12天 (含测试12天,中途春节休7天)`
> - 优化：`迭代canset前段条件满足`、`使概念识别越来越准`、`修复前段条件满足不完全的问题`

> ##### 2022.12.17 `耗时16天`
> - AIRank：`概念识别和时序识别的综合竞争: 支持强度竞争`、`回测`

> ##### 2022.11.30 `耗时17天`
> - 二十测：`回归测试`

> ##### 2022.10.15 `耗时45天`
> - 优化：`抽具象多层多样性优化`、`持久化与复用概念相似度`、`迭代时序识别：持久化与复用indexDic`、`canset演化周期`、`废除TO反思识别`

> ##### 2022.10.08 `耗时7天`
> - 测试：`废弃isMem`、`继续测试反思`

> ##### 2022.09.18 `耗时12天`
> - 测试：`测试任务失效机制`

> ##### 2022.09.01 `耗时17天`
> - 调优：`任务失效机制`

> ##### 2022.08.06 `耗时25天`
> - 测试：`测试TCRefrection`、`性能优化`

> ##### 2022.07.05 `耗时22天 中途旅游休8天`
> - 十九测：`迭代TCRefrection反思`

> ##### 2022.06.05 `耗时9天 中途疫情休20天`
> - 梳理TC数据流：`决策配置调整: 快慢思考部分`、`学时统计 & 用时概率`、`测连续飞躲`、`Analyst综合排名`

> ##### 2022.05.20 `耗时15天`
> - 梳理TC数据流：`识别准确度优化：逐层宽入窄出`、`数据流：整体观`、`快思考慢思考`、`TCActYes每帧O反省`

> ##### 2022.05.11 `耗时9天`
> - 性能优化：`优化pFo识别性能`、`迭代Demand支持多pFos`、`十八测回归测试`

> ##### 2022.05.04 `耗时7天`
> - 工具优化：`十七测`、`强化训练工具优化：支持模拟重启`、`思维可视化工具优化：支持手势缩放`

> ##### 2022.04.28 `耗时6天`
> - 梳理TC数据流：`整体兼顾`、`各线竞争`

> ##### 2022.04.23 `耗时5天`
> - 十六测：`性能优化`、`强化学习训练`

> ##### 2022.03.28 `耗时8天 中途疫情休17天`
> - 强化训练：`开发强化学习稳定性训练器: RLTrainer`

> ##### 2022.03.13 `耗时15天`
> - 思维可视化工具：`TOMVisionV2迭代: 思维可视化`

> ##### 2022.02.16 `耗时25天 中途春节疫情休25天`
> - 十五测：`春节结束，开工回归测试`

> ##### 2022.01.15 `耗时5天`
> - 十四测：`回测相近匹配`

> ##### 2022.01.10 `耗时5天`
> - 相近匹配：`相近匹配`

> ##### 2021.12.26 `耗时15天`
> - 回归十三测：`新螺旋架构测试`、`反省分裂迭代测试`

> ##### 2021.12.22 `耗时4天`
> - 反省迭代：`hSolution从SP取解决方案`、`分裂:感性反省 和 理性反省`、`废弃HN`

> ##### 2021.11.18 `耗时34天`
> - 思维控制器架构大迭代：`完善螺旋架构`、`废弃宏微决策`、`反思融入识别`、`工作记忆树迭代`、`迭代综合评价`、`末枝最优路径`

> ##### 2021.11.04 `耗时14天`
> - R决策模式迭代：`FRS评价器迭代`、`废弃dsFo`、`废弃PM`、`废弃GL`

> ##### 2021.10.19 `耗时15天`
> - PM稳定性迭代：`VRS评价器迭代`、`VRSTarget修正目标`

> ##### 2021.09.29 `耗时20天`
> - v2.0十二测与训练：`IRT的SP参与VRS评分`、`SP定义由顺逆改为好坏`、`紧急状态不反思`、`主客观互卡问题`、`tir_OPushM迭代：IRT的理性失效`

> ##### 2021.09.14 `耗时15天`
> - 网络节点类型排查：`指针集成type`、`自检测试`、`网络at&ds&type错误大排查`

> ##### 2021.07.08 `耗时66天`
> - v2.0十一测与训练：`子任务回测`、`R决策模式`、`防撞训练`

> ##### 2021.06.25 `耗时13天`
> - 子任务细节改动：`子任务的已发生截点`、`同级任务协作`

> ##### 2021.06.05 `耗时17天`
> - 子任务细节改动：`子任务协同`、`子任务不应期`

> ##### 2021.05.24 `耗时1个月`
> - v2.0十测与训练：`子任务测试`、`防撞训练`

> ##### 2021.04.10 `耗时44天`
> - v2.0九测与训练：`觅食训练&变向觅食训练`

> ##### 2021.04.07 `耗时15天`
> - HNGL嵌套迭代：`内中外类比迭代v3,v4`、`迭代getInnerV3()`、`RFo抽具象关联`

> ##### 2021.03.12 `耗时20天`
> - v2.0八测与训练：`R-模式测试`、`觅食和防撞融合训练`

> ##### 2021.02.23 `耗时37天`
> - 决策理性迭代：`规划决策`、`子任务迭代：理性反思`、`来的及评价`、`嵌套关联`

> ##### 2021.01.30 `耗时4天`
> - R-决策模式V3迭代、反向反馈外类比

> ##### 2021.01.23 `耗时35天`
> - v2.0七测与训练 `防撞训练`、`R-模式测试`

> ##### 2021.01.15 `耗时8天`
> - In反省类比迭代、R-决策模式V2迭代 `迭代触发机制: 生物钟触发器`

> ##### 2020.12.24 `耗时20天`
> - v2.0六测与训练 `多向飞行正常`

> ##### 2020.12.07 `耗时1个月`
> - AIScore评价器整理完善：`时序理性评价：FRS`、`稀疏码理性评价：VRS`

> ##### 2020.11.07 `耗时1个月`
> - v2.0五测与训练

> ##### 2020.10.21 `耗时15天`
> - TIR_Alg支持多识别

> ##### 2020.09.01 `耗时1个月`
> - v2.0四测与训练

> ##### 2020.08.12 `耗时27天`
> - Out反省类比迭代 (DiffAnalogy)、生物钟(AITime)、PM理性评价迭代v2

> ##### 2020.06.28 `5天`
> - 决策迭代：PM理性评价

> ##### 2020.06.06 `耗时2个月`
> - v2.0三测与训练

> ##### 2020.05.15 `耗时20天`
> - 决策迭代：（根据`输出期短时记忆`使决策递归与外循环更好协作）

> ##### 2020.04.21 `耗时1个月`
> - 决策迭代：（根据`输入期短时记忆`使决策支持四模式）

> ##### 2020.03.31 `耗时1个月`
> - 迭代外类比: 新增反向反馈类比 (In反省类比) (构建SP正负时序、应用SP于决策的MC中、迭代反思)

> ##### 2020.02.20 `耗时18天`
> - 稀疏码模糊匹配

> ##### 2019.12.27 `持续3个月`
> - v2.0二测与规划性训练－－回归小鸟训练

> ##### 2019.11.22 `耗时1个月`
> - 理性思维——反思评价

> ##### 2019.09.30 `耗时2个月`
> - 理性思维——TOR迭代 (行为化架构迭代、支持瞬时网络)

> ##### 2019.08.25 `耗时1个月`
> - 理性思维——TIR迭代 (时序识别、时序预测、价值预判)

> ##### 2019.06.20 `耗时2个月`
> - v2.0版本基础测试改BUG 与 训练

> ##### 2019.06.05 `写完耗时15天,调至可用性达到标准至45天`
> - v2.0一测－－小鸟训练——神经网络可视化v2.0

> ##### 2019.05.01 `耗时1个月`
> - 优化性能——`XGWedis异步持久化` 和 `短时内存网络`

> ##### 2019.03.01 `耗时2个月`
> - 内类比 （与外类比相对）

> ##### 2019.01.21 `耗时40天`
> - 迭代决策循环 （行为化等）

> ##### 2018.11.28 `耗时2个月`
> - 迭代神经网络 (区分动态时序与静态概念)

> ##### 2018.11.05 `规划耗时20天`
> - 势 (小鸟生存演示) (v2.0开始开发)

> ##### 2018.10.21 `耗时0天`
> - v1.0.0 (he4o内核发布)

> ##### 2018.10.20 `耗时0天`
> - 螺旋熵减机 (产生智能的环境)

> ##### 2018.08.29 `耗时2个月`
> - MOL

> ##### 2018.08.01 `耗时1个月`
> - MIL & MOL (重构中层动循环)

> ##### 2018.07.01 `耗时1个月`
> - HELIX (定义、相对和循环呈现的螺旋型)

> ##### 2018.06.01 `耗时1个月`
> - 三层循环大改版 (mv循环,思维网络循环,智能体与现实世界循环)

> ##### 2018.05.01 `耗时1个月`
> - 相对 (he4o实现定义,横向相对,纵向相对)

> ##### 2018.02.01 `耗时3个月`
> - 宏微 (前身是拆分与整合,宏微一体)

> ##### 2017.12.09 `耗时2个月`
> - 定义 (从0到1)

> ##### 2017.11.10 `耗时1个月`
> - 规则 (最简)

> ##### 2017.09.20 `耗时50天`
> - DOP_面向数据编程
> - GNOP_动态构建网络

> ##### 2017.08.23 `耗时1个月`
> - 神经网络 (算法,抽具象网络)

> ##### 2017.08.02 `耗时20天`
> - MindValue（价值）

> ##### 2017.07.10 `耗时20天`
> - 树BrainTree(参考N3P7,N3P8)

> ##### 2017.06.01 `耗时40天`
> - 三维架构(参考笔记/AI/框架)

> ##### 2017.05.22 `耗时10天`
> - OOP编程思想->数据语言 (OOP2DataLanguage)

> ##### 2017.05.21 `耗时1天`
> - 重绘了新版架构图; (AIFoundation)

> ##### 2017.04.21 `耗时1个月`
> - 金字塔架构

> ##### 2017.03.21 `耗时1个月`
> - 分层架构

> ##### 2017.02.21 `耗时1个月`
> - 流程架构
