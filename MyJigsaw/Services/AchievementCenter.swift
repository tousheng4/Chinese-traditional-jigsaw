//
//  AchievementCenter.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/15.
//

import Foundation
import Combine

@MainActor
class AchievementCenter: ObservableObject {
    static let shared = AchievementCenter()

    // 输入依赖
    private let contentManager = ContentManager.shared
    private let persistenceManager = PersistenceManager.shared

    // 输出：UI订阅的成就数据
    @Published var achievements: [AchievementViewData] = []
    @Published var newlyUnlockedAchievement: AchievementDefinition?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // 等待内容管理器初始化完成后再设置成就
        DispatchQueue.main.async { [weak self] in
            self?.setupAchievements()
        }
    }

    // MARK: - Public Methods

    /// 评估所有成就（应用启动时调用）
    func evaluateAllAchievements() {
        let moduleAchievements = AchievementDefinition.moduleAchievements(for: contentManager.categories)
        let globalAchievements = AchievementDefinition.globalAchievements

        let allAchievements = moduleAchievements + globalAchievements

        for achievement in allAchievements {
            evaluateAchievement(achievement)
        }
        updateAchievementsArray()
    }

    /// 评估特定模块的成就（关卡完成时调用）
    func evaluateModuleAchievement(categoryId: String) {
        let moduleAchievements = AchievementDefinition.moduleAchievements(for: contentManager.categories)
        let relevantAchievements = moduleAchievements.filter { achievement in
            switch achievement.criterion {
            case .completeAllLevels(let achCategoryId, _, _):
                return achCategoryId == categoryId
            default:
                return false
            }
        }

        for achievement in relevantAchievements {
            evaluateAchievement(achievement)
        }
        updateAchievementsArray()
    }

    /// 处理关卡完成事件（统一入口：写进度 + 评估 + 触发解锁事件）
    func handleLevelCompleted(levelStableId: String, categoryId: String) {
        // 评估模块相关成就
        evaluateModuleAchievement(categoryId: categoryId)

        // 评估可能受影响的全局成就
        let globalAchievements = AchievementDefinition.globalAchievements
        for achievement in globalAchievements {
            // 只评估可能受关卡完成影响的成就
            switch achievement.criterion {
            case .completeLevelInTime, .completeWithFewMoves, .completeLevelsInRow,
                 .completeAllCategories, .firstTimePlayer:
                evaluateAchievement(achievement)
            case .speedRunner:
                // 速度成就需要实时更新
                evaluateAchievement(achievement)
            default:
                break
            }
        }

        // 检查是否有新解锁的成就
        checkForNewlyUnlockedAchievements()
    }

    // MARK: - Private Methods

    private func setupAchievements() {
        // 初始化所有成就的状态
        let moduleAchievements = AchievementDefinition.moduleAchievements(for: contentManager.categories)
        let globalAchievements = AchievementDefinition.globalAchievements
        let allAchievements = moduleAchievements + globalAchievements

        for achievement in allAchievements {
            let state = getOrCreateAchievementState(for: achievement.id)
            let viewData = AchievementViewData(achievement: achievement, state: state)
            achievements.append(viewData)
        }
    }

    private func evaluateAchievement(_ achievement: AchievementDefinition) {
        switch achievement.criterion {
        case .completeAllLevels(let categoryId, let difficultyScope, let countsOnly):
            evaluateModuleCompletionAchievement(
                achievementId: achievement.id,
                categoryId: categoryId,
                difficultyScope: difficultyScope,
                countsOnly: countsOnly
            )
        case .completeLevelInTime(let maxTimeSeconds, let minDifficulty):
            evaluateSpeedAchievement(
                achievementId: achievement.id,
                maxTimeSeconds: maxTimeSeconds,
                minDifficulty: minDifficulty
            )
        case .completeWithFewMoves(let maxMoves):
            evaluateEfficiencyAchievement(
                achievementId: achievement.id,
                maxMoves: maxMoves
            )
        case .completeLevelsInRow(let count):
            evaluateStreakAchievement(
                achievementId: achievement.id,
                requiredCount: count
            )
        case .completeAllCategories:
            evaluateAllCategoriesAchievement(achievementId: achievement.id)
        case .firstTimePlayer:
            evaluateFirstTimePlayerAchievement(achievementId: achievement.id)
        case .speedRunner(let totalTimeSeconds):
            evaluateSpeedRunnerAchievement(
                achievementId: achievement.id,
                totalTimeSeconds: totalTimeSeconds
            )
        }
    }

    private func evaluateModuleCompletionAchievement(
        achievementId: String,
        categoryId: String,
        difficultyScope: DifficultyScope?,
        countsOnly: Bool
    ) {
        // 获取该分类下所有计入成就的关卡
        let levelsInCategory = contentManager.getLevels(forCategoryId: categoryId)
            .filter { $0.countsForModuleAchievement }

        let totalLevels = levelsInCategory.count

        // 获取已完成的关卡数量
        let completedLevels = levelsInCategory.filter { level in
            let progress = persistenceManager.getGameProgress(forStableId: level.stableId)
            return progress.isCompleted
        }.count

        // 更新成就状态
        updateAchievementState(achievementId: achievementId, completed: completedLevels, total: totalLevels)
    }

    private func evaluateSpeedAchievement(achievementId: String, maxTimeSeconds: Int, minDifficulty: DifficultyScope?) {
        // 检查是否有任何关卡在指定时间内完成
        let allLevels = contentManager.categories.flatMap { category in
            contentManager.getLevels(for: category.id)
        }

        var hasAchievement = false
        for level in allLevels {
            let progress = persistenceManager.getGameProgress(forStableId: level.stableId)
            if progress.isCompleted,
               let bestTime = progress.bestTime,
               bestTime <= TimeInterval(maxTimeSeconds) {
                // 检查难度要求
                if let minDifficulty = minDifficulty {
                    let levelDifficulty = level.difficulty
                    if levelDifficulty.rawValue >= minDifficulty.rawValue {
                        hasAchievement = true
                        break
                    }
                } else {
                    hasAchievement = true
                    break
                }
            }
        }

        updateAchievementState(achievementId: achievementId, completed: hasAchievement ? 1 : 0, total: 1)
    }

    private func evaluateEfficiencyAchievement(achievementId: String, maxMoves: Int) {
        // 检查是否有任何关卡用少于指定步数完成
        let allLevels = contentManager.categories.flatMap { category in
            contentManager.getLevels(for: category.id)
        }

        var hasAchievement = false
        for level in allLevels {
            let progress = persistenceManager.getGameProgress(forStableId: level.stableId)
            if progress.isCompleted,
               let bestMoves = progress.bestMoves,
               bestMoves <= maxMoves {
                hasAchievement = true
                break
            }
        }

        updateAchievementState(achievementId: achievementId, completed: hasAchievement ? 1 : 0, total: 1)
    }

    private func evaluateStreakAchievement(achievementId: String, requiredCount: Int) {
        // 计算当前连续完成的关卡数
        let allLevels = contentManager.categories.flatMap { category in
            contentManager.getLevels(for: category.id)
        }

        // 按完成时间排序，找到最近的连续完成序列
        let completedLevels = allLevels.filter { level in
            let progress = persistenceManager.getGameProgress(forStableId: level.stableId)
            return progress.isCompleted
        }.sorted { level1, level2 in
            let progress1 = persistenceManager.getGameProgress(forStableId: level1.stableId)
            let progress2 = persistenceManager.getGameProgress(forStableId: level2.stableId)
            return progress1.lastPlayedAt > progress2.lastPlayedAt
        }

        // 检查是否有连续的完成记录（时间间隔不超过1小时）
        var currentStreak = 0
        var lastCompletionTime: Date?

        for level in completedLevels {
            let progress = persistenceManager.getGameProgress(forStableId: level.stableId)
            let completionTime = progress.lastPlayedAt
            if let lastTime = lastCompletionTime {
                let timeDiff = completionTime.timeIntervalSince(lastTime)
                if abs(timeDiff) < 3600 { // 1小时内
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            lastCompletionTime = completionTime
        }

        updateAchievementState(achievementId: achievementId, completed: min(currentStreak, requiredCount), total: requiredCount)
    }

    private func evaluateAllCategoriesAchievement(achievementId: String) {
        // 检查是否所有分类都被完全完成
        let categories = contentManager.categories.filter { $0.title != "自制拼图" } // 排除自制拼图
        var completedCategories = 0

        for category in categories {
            let levels = contentManager.getLevels(for: category.id)
            let completedLevels = levels.filter { level in
                let progress = persistenceManager.getGameProgress(forStableId: level.stableId)
                return progress.isCompleted
            }.count

            if completedLevels == levels.count {
                completedCategories += 1
            }
        }

        updateAchievementState(achievementId: achievementId, completed: completedCategories, total: categories.count)
    }

    private func evaluateFirstTimePlayerAchievement(achievementId: String) {
        // 检查是否有任何关卡被完成过
        let allLevels = contentManager.categories.flatMap { category in
            contentManager.getLevels(for: category.id)
        }

        let hasCompletedAny = allLevels.contains { level in
            let progress = persistenceManager.getGameProgress(forStableId: level.stableId)
            return progress.isCompleted
        }

        updateAchievementState(achievementId: achievementId, completed: hasCompletedAny ? 1 : 0, total: 1)
    }

    private func evaluateSpeedRunnerAchievement(achievementId: String, totalTimeSeconds: Int) {
        // 计算所有关卡的总游戏时间
        let allLevels = contentManager.categories.flatMap { category in
            contentManager.getLevels(for: category.id)
        }

        var totalTime: TimeInterval = 0
        for level in allLevels {
            let progress = persistenceManager.getGameProgress(forStableId: level.stableId)
            if progress.isCompleted, let bestTime = progress.bestTime {
                totalTime += bestTime
            }
        }

        let hasAchievement = totalTime >= TimeInterval(totalTimeSeconds)
        updateAchievementState(achievementId: achievementId, completed: hasAchievement ? 1 : 0, total: 1)
    }

    private func getOrCreateAchievementState(for achievementId: String) -> AchievementState {
        if let state = getAchievementState(for: achievementId) {
            return state
        } else {
            let newState = AchievementState(achievementId: achievementId)
            saveAchievementState(newState)
            return newState
        }
    }

    private func getAchievementState(for achievementId: String) -> AchievementState? {
        // 从PersistenceManager获取（需要先实现）
        return persistenceManager.getAchievementState(for: achievementId)
    }

    private func updateAchievementState(achievementId: String, completed: Int, total: Int) {
        var state = getOrCreateAchievementState(for: achievementId)
        let wasUnlocked = state.isUnlocked

        state.updateProgress(completed: completed, total: total)

        // 如果刚解锁，记录为新解锁成就
        if state.isUnlocked && !wasUnlocked {
            let moduleAchievements = AchievementDefinition.moduleAchievements(for: contentManager.categories)
            let globalAchievements = AchievementDefinition.globalAchievements
            let allAchievements = moduleAchievements + globalAchievements

            if let achievement = allAchievements.first(where: { $0.id == achievementId }) {
                newlyUnlockedAchievement = achievement
            }
        }

        saveAchievementState(state)
    }

    private func saveAchievementState(_ state: AchievementState) {
        persistenceManager.saveAchievementState(state)
    }

    private func updateAchievementsArray() {
        let moduleAchievements = AchievementDefinition.moduleAchievements(for: contentManager.categories)
        let globalAchievements = AchievementDefinition.globalAchievements
        let allAchievements = moduleAchievements + globalAchievements

        achievements = allAchievements.map { achievement in
            let state = getOrCreateAchievementState(for: achievement.id)
            return AchievementViewData(achievement: achievement, state: state)
        }
    }

    private func checkForNewlyUnlockedAchievements() {
        // 这个方法会在一定延迟后清除新解锁成就通知
        // 避免一直显示解锁提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.newlyUnlockedAchievement = nil
        }
    }

    /// 重置所有成就状态
    func resetAchievements() {
        // 清除所有成就状态
        achievements.removeAll()
        newlyUnlockedAchievement = nil

        // 重新初始化所有成就
        evaluateAllAchievements()

        // 调试输出已移除，减少控制台噪音
    }
}
