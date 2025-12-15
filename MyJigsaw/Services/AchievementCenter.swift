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
        for achievement in moduleAchievements {
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
            }
        }

        for achievement in relevantAchievements {
            evaluateAchievement(achievement)
        }
        updateAchievementsArray()
    }

    /// 处理关卡完成事件（统一入口：写进度 + 评估 + 触发解锁事件）
    func handleLevelCompleted(levelId: UUID, categoryId: String) {
        // 评估相关成就
        evaluateModuleAchievement(categoryId: categoryId)

        // 检查是否有新解锁的成就
        checkForNewlyUnlockedAchievements()
    }

    // MARK: - Private Methods

    private func setupAchievements() {
        // 初始化所有成就的状态
        let moduleAchievements = AchievementDefinition.moduleAchievements(for: contentManager.categories)
        for achievement in moduleAchievements {
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
            let progress = persistenceManager.getGameProgress(for: level.id)
            return progress.isCompleted
        }.count

        // 更新成就状态
        updateAchievementState(achievementId: achievementId, completed: completedLevels, total: totalLevels)
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
            if let achievement = moduleAchievements.first(where: { $0.id == achievementId }) {
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
        achievements = moduleAchievements.map { achievement in
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
}
