//
//  PersistenceManager.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import Foundation
import Combine

// MARK: - Persistence Manager
class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Keys for UserDefaults
    private enum Keys {
        static let puzzleProgress = "puzzle_progress"
        static let unlockedCategories = "unlocked_categories"
        static let appFirstLaunch = "app_first_launch"
        static let achievementStates = "achievement_states"
    }
    
    private init() {}
    
    // MARK: - Puzzle Progress
    func saveGameProgress(levelId: UUID, isCompleted: Bool, time: TimeInterval?, moves: Int?) {
        var progress = getGameProgress(for: levelId)

        progress.isCompleted = progress.isCompleted || isCompleted
        progress.lastPlayedAt = Date()

        if let time = time, progress.bestTime == nil || time < progress.bestTime! {
            progress.bestTime = time
        }

        if let moves = moves, progress.bestMoves == nil || moves < progress.bestMoves! {
            progress.bestMoves = moves
        }

        saveProgress(progress)

        // 通知UI更新
        objectWillChange.send()
    }
    
    func getGameProgress(for levelId: UUID) -> PuzzleProgress {
        let allProgress = getAllProgress()
        return allProgress.first { $0.levelId == levelId } ?? PuzzleProgress(levelId: levelId)
    }
    
    func getAllProgress() -> [PuzzleProgress] {
        guard let data = userDefaults.data(forKey: Keys.puzzleProgress),
              let progress = try? decoder.decode([PuzzleProgress].self, from: data) else {
            return []
        }
        return progress
    }
    
    private func saveProgress(_ progress: PuzzleProgress) {
        var allProgress = getAllProgress()
        
        if let index = allProgress.firstIndex(where: { $0.levelId == progress.levelId }) {
            allProgress[index] = progress
        } else {
            allProgress.append(progress)
        }
        
        if let data = try? encoder.encode(allProgress) {
            userDefaults.set(data, forKey: Keys.puzzleProgress)
        }
    }
    
    // MARK: - App State
    func isFirstLaunch() -> Bool {
        let isFirst = !userDefaults.bool(forKey: Keys.appFirstLaunch)
        if isFirst {
            userDefaults.set(true, forKey: Keys.appFirstLaunch)
        }
        return isFirst
    }
    
    // MARK: - Unlocked Categories
    func unlockCategory(_ categoryId: UUID) {
        var unlockedCategories = getUnlockedCategories()
        if !unlockedCategories.contains(categoryId) {
            unlockedCategories.append(categoryId)
            userDefaults.set(unlockedCategories.map { $0.uuidString }, forKey: Keys.unlockedCategories)
        }
    }
    
    func getUnlockedCategories() -> [UUID] {
        guard let strings = userDefaults.array(forKey: Keys.unlockedCategories) as? [String] else {
            return []
        }
        return strings.compactMap { UUID(uuidString: $0) }
    }
    
    func isCategoryUnlocked(_ categoryId: UUID) -> Bool {
        return getUnlockedCategories().contains(categoryId)
    }

    // MARK: - Achievement States
    func saveAchievementState(_ state: AchievementState) {
        var allStates = getAllAchievementStates()

        if let index = allStates.firstIndex(where: { $0.achievementId == state.achievementId }) {
            allStates[index] = state
        } else {
            allStates.append(state)
        }

        if let data = try? encoder.encode(allStates) {
            userDefaults.set(data, forKey: Keys.achievementStates)
        }

        // 通知UI更新
        objectWillChange.send()
    }

    func getAchievementState(for achievementId: String) -> AchievementState? {
        let allStates = getAllAchievementStates()
        return allStates.first { $0.achievementId == achievementId }
    }

    func getAllAchievementStates() -> [AchievementState] {
        guard let data = userDefaults.data(forKey: Keys.achievementStates),
              let states = try? decoder.decode([AchievementState].self, from: data) else {
            return []
        }
        return states
    }
}
