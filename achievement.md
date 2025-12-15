1. 成就定义与判定规则
1.1 成就类型

模块通关成就（Module Completion Achievement）
当用户完成某一模块（主题分类，如“年画”“脸谱”“敦煌”“国画”）下 所有关卡 时解锁该模块成就。

1.2 判定口径（建议固定下来写入规格）

为避免后期歧义，建议明确以下三点：

“完成关卡”的定义

关卡完成：用户至少一次达成“拼图完成态”（所有拼图块锁定/归位），记为 isCompleted = true。

重复通关不改变“完成”状态，但可更新最佳记录（时间/步数）。

“模块的所有关卡”的范围

默认口径：该模块下 所有已发布且可计入的关卡。

若存在“隐藏关/活动关/付费关”，需标注其是否计入模块成就：

countsForModuleAchievement: Bool（建议在关卡元数据中配置）。

这样可实现“基础模块成就”与“全收集成就”区分，而不破坏主线节奏。

难度维度是否参与成就判定（常见策略）

策略：模块成就只要求“任意难度完成一次”。


2. 数据模型与元数据设计

成就系统本质上由两部分构成：静态定义（成就是什么）与 动态状态（用户是否已解锁、进度多少）。

2.1 静态：关卡清单（Catalog）

关卡建议以本地 JSON/Plist 或 Swift 常量维护，至少包含：

Level

id: String

categoryId: String（模块/主题）

title: String

assetName: String

gridSize / difficultyConfig

countsForModuleAchievement: Bool（是否计入模块成就）

（可选）releaseVersion: Int（用于版本化成就，见第 5 节）

2.2 动态：用户关卡进度（Progress）

LevelProgress

levelId: String

isCompleted: Bool

bestTime: TimeInterval?

bestMoves: Int?

completedAt: Date?

2.3 静态：成就定义（Definition）

AchievementDefinition

id: String（如 ach_category_nianhua_complete）

title: String

description: String

iconAssetName: String

criterion: AchievementCriterion

AchievementCriterion（可用 enum）

completeAllLevels(categoryId: String, difficultyScope: DifficultyScope?, countsOnly: Bool = true)

其中 difficultyScope 用于策略 B（某难度全通）

2.4 动态：成就状态（State）

AchievementState

achievementId: String

isUnlocked: Bool

unlockedAt: Date?

progressCompleted: Int

progressTotal: Int

lastEvaluatedAt: Date

progressCompleted/Total 可选择“计算型”或“存储型”。建议：UI 展示用可缓存，判定以实时计算为准，避免一致性问题。

3. 解锁算法与触发时机（核心逻辑）
3.1 何时计算成就

建议有两条触发链路：

应用启动 / 关卡清单加载后：全量评估一次（保证数据一致）。

关卡完成事件发生时：只增量评估该关卡所属模块的成就（高效）。

3.2 模块成就的评估步骤（策略 A：任意难度完成一次）

对给定 categoryId：

从关卡清单中过滤出：

level.categoryId == categoryId

level.countsForModuleAchievement == true
得到集合 S_all，其大小为 total.

从用户进度中取出已完成集合：

isCompleted == true 且 levelId ∈ S_all
得到 S_done，其大小为 completed.

更新成就进度：

progressTotal = total

progressCompleted = completed

解锁判定：

若 completed == total 且 total > 0 且此前未解锁
则 isUnlocked = true，记录 unlockedAt = now，并触发解锁反馈（弹窗/Toast/音效/触感）。

3.3 增量更新的关键点

当用户完成某关卡 levelId 时：

先写入该关卡进度：LevelProgress.isCompleted = true（持久化）

再执行：evaluateModuleAchievement(categoryId: level.categoryId)
这样可保证“先有事实，再做裁决”。

4. SwiftUI 实现组织方式（建议架构）
4.1 负责成就的中心组件

建立一个单一职责的“成就中心”（可为 @MainActor 的 Observable）：

AchievementCenter

输入：LevelCatalog（关卡静态定义）、ProgressStore（用户进度读写）

输出：[AchievementViewData]（供 UI 展示）

方法：

evaluateAllAchievements()

evaluateModuleAchievement(categoryId:)

handleLevelCompleted(levelId:)（统一入口：写进度 + 评估 + 触发解锁事件）

UI 层只订阅成就中心的状态（避免在 View 里做判定逻辑）。

4.2 解锁反馈的 SwiftUI 呈现

解锁时发出一个可观察事件，例如：

@Published var newlyUnlockedAchievement: AchievementDefinition?

在根视图或路由容器中监听该字段，弹出：

Toast/Overlay（不打断）

或 Sheet（更仪式感）
并提供“去看看成就”按钮跳转到成就页。

5. 持久化策略与“新增关卡”问题（强烈建议提前处理）

模块成就最大坑点：版本迭代后新增关卡会改变“全通”的含义。

5.1 两种可选策略

策略 1：成就是“动态全通”（随关卡更新而更新）

优点：定义朴素；永远表示“当前版本已全通”。

缺点：用户曾经解锁过的模块成就，可能因新关卡加入而“失效”。

解决：不建议把 isUnlocked 回滚为 false；而是把成就语义写为“完成当前已发布全部关卡”并允许状态再次变为“未满进度”，但不撤销“曾解锁”徽章——会引发体验分裂。

策略 2：成就是“版本化全通”（推荐）

在关卡清单中维护 catalogVersion 或关卡的 releaseVersion。

成就状态记录：unlockedForCatalogVersion: Int 或 unlockedAtVersion: Int。

解锁条件：完成所有 releaseVersion <= currentVersion 的关卡。

新关卡加入后：

已解锁成就不被撤销；

可新增“全通 +1”进度，或新增“扩展包全通成就”。

对文化内容型产品而言，版本化策略更符合“收藏”的叙事：曾经圆满，仍然圆满；后来又有新卷可续。

6. 可测试性与验收标准
6.1 单元测试建议

给定模块关卡 5 个，完成 4 个：未解锁，进度 4/5。

完成第 5 个：触发一次解锁事件，记录 unlockedAt。

重复完成已完成关卡：不重复触发解锁事件。

countsForModuleAchievement = false 的关卡不计入总数。

total = 0（模块暂无关卡）时不得解锁。

6.2 验收口径（可写入 DoD）

成就页显示模块成就列表与进度条（completed/total）。

完成最后一关时，成就解锁提示稳定触发且仅触发一次。

重启应用后解锁状态与解锁时间仍正确。