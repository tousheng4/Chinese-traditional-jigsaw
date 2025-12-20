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

    // 调试模式控制 - 设置为true启用详细调试输出
    private let isDebugMode = false
    private let fileManager = FileManager.default

    // Keys for UserDefaults (fallback)
    private enum Keys {
        static let puzzleProgress = "puzzle_progress"
        static let unlockedCategories = "unlocked_categories"
        static let appFirstLaunch = "app_first_launch"
        static let achievementStates = "achievement_states"
    }

    // File-based storage paths
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var puzzleProgressURL: URL {
        documentsDirectory.appendingPathComponent("puzzle_progress.json")
    }

    private var achievementStatesURL: URL {
        documentsDirectory.appendingPathComponent("achievement_states.json")
    }

    private var unlockedCategoriesURL: URL {
        documentsDirectory.appendingPathComponent("unlocked_categories.json")
    }

    private init() {
        encoder.outputFormatting = .prettyPrinted
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601

        print("📁 Documents目录: \(documentsDirectory.path)")
        print("📁 关卡进度文件路径: \(puzzleProgressURL.path)")
        print("📁 成就状态文件路径: \(achievementStatesURL.path)")
        print("📁 解锁分类文件路径: \(unlockedCategoriesURL.path)")

        // 迁移旧数据（如果有的话）
        migrateOldDataIfNeeded()

        if isDebugMode {
            print("📁 Documents目录: \(documentsDirectory.path)")
            print("📁 关卡进度文件路径: \(puzzleProgressURL.path)")
            print("📁 成就状态文件路径: \(achievementStatesURL.path)")
            print("📁 解锁分类文件路径: \(unlockedCategoriesURL.path)")
        }
    }

    // MARK: - Data Migration
    private func migrateOldDataIfNeeded() {
        // 检查是否已有文件数据
        if fileManager.fileExists(atPath: puzzleProgressURL.path) {
            if isDebugMode {
                print("✅ 使用文件系统存储的进度数据")
            }
            return
        }

        // 迁移UserDefaults中的旧数据到文件系统
        if isDebugMode {
            print("🔄 迁移旧的UserDefaults数据到文件系统...")
        }

        // 迁移关卡进度
        if let progressData = userDefaults.data(forKey: Keys.puzzleProgress),
           let progress = try? decoder.decode([PuzzleProgress].self, from: progressData) {
            saveProgressToFile(progress)
            if isDebugMode {
                print("   迁移了 \(progress.count) 条关卡进度记录")
            }
        }

        // 迁移成就状态
        if let achievementData = userDefaults.data(forKey: Keys.achievementStates),
           let achievements = try? decoder.decode([AchievementState].self, from: achievementData) {
            saveAchievementStatesToFile(achievements)
            if isDebugMode {
                print("   迁移了 \(achievements.count) 条成就状态记录")
            }
        }

        // 迁移解锁分类
        if let categoriesData = userDefaults.array(forKey: Keys.unlockedCategories) as? [String],
           let categories = categoriesData.compactMap({ UUID(uuidString: $0) }) as [UUID]? {
            saveUnlockedCategoriesToFile(categories)
            if isDebugMode {
                print("   迁移了 \(categories.count) 个解锁分类")
            }
        }

        if isDebugMode {
            print("✅ 数据迁移完成")
        }
    }
    
    // MARK: - Puzzle Progress
    func saveGameProgress(levelStableId: String, isCompleted: Bool, time: TimeInterval?, moves: Int?) {
        var progress = getGameProgress(forStableId: levelStableId)

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

        if isDebugMode {
            print("💾 保存关卡进度: stableId=\(levelStableId), isCompleted=\(isCompleted), time=\(String(describing: time)), moves=\(String(describing: moves))")
        }
    }

    func getGameProgress(forStableId levelStableId: String) -> PuzzleProgress {
        let allProgress = getAllProgress()
        return allProgress.first { $0.levelStableId == levelStableId } ?? PuzzleProgress(levelStableId: levelStableId)
    }

    // 兼容性方法
    func saveGameProgress(levelId: UUID, isCompleted: Bool, time: TimeInterval?, moves: Int?) {
        // 转换为使用stableId
        let stableId = levelId.uuidString
        saveGameProgress(levelStableId: stableId, isCompleted: isCompleted, time: time, moves: moves)
    }

    func getGameProgress(for levelId: UUID) -> PuzzleProgress {
        // 先尝试用stableId查找，如果找不到则创建兼容性记录
        let stableId = levelId.uuidString
        let progress = getGameProgress(forStableId: stableId)

        // 如果找到的是兼容性记录（levelStableId == levelId.uuidString），说明是旧数据
        if progress.levelStableId == levelId.uuidString && progress.id == UUID() {
            // 返回一个空的进度，表示没有找到
            return PuzzleProgress(levelStableId: stableId)
        }

        return progress
    }

    func getAllProgress() -> [PuzzleProgress] {
        // 优先从文件系统加载
        if let progress = loadProgressFromFile() {
            return progress
        }

        // 回退到UserDefaults（用于迁移）
        guard let data = userDefaults.data(forKey: Keys.puzzleProgress),
              let progress = try? decoder.decode([PuzzleProgress].self, from: data) else {
            if isDebugMode {
                print("❌ 无法加载关卡进度数据")
            }
            return []
        }
        if isDebugMode {
            print("📖 已从UserDefaults加载 \(progress.count) 条关卡进度记录")
        }
        return progress
    }

    private func saveProgress(_ progress: PuzzleProgress) {
        var allProgress = getAllProgress()

        if let index = allProgress.firstIndex(where: { $0.levelStableId == progress.levelStableId }) {
            allProgress[index] = progress
        } else {
            allProgress.append(progress)
        }

        saveProgressToFile(allProgress)
    }

    // MARK: - File-based Progress Storage
    private func saveProgressToFile(_ progress: [PuzzleProgress]) {
        if isDebugMode {
            print("💾 正在保存关卡进度到文件: \(puzzleProgressURL.path)")
        }

        do {
            let data = try encoder.encode(progress)
            if isDebugMode {
                print("📊 编码后的数据大小: \(data.count) bytes")
                print("📋 要保存的记录数量: \(progress.count)")

                // 打印前几个记录的详细信息
                for (index, p) in progress.prefix(3).enumerated() {
                    print("   记录 \(index + 1): stableId=\(p.levelStableId), isCompleted=\(p.isCompleted), bestTime=\(String(describing: p.bestTime)), bestMoves=\(String(describing: p.bestMoves))")
                }
            }

            try data.write(to: puzzleProgressURL, options: .atomic)
            if isDebugMode {
                print("✅ 成功保存 \(progress.count) 条关卡进度记录到文件")

                // 验证文件是否真的存在
                if fileManager.fileExists(atPath: puzzleProgressURL.path) {
                    print("✅ 文件已确认存在")
                } else {
                    print("❌ 文件保存后不存在！")
                }
            }

        } catch {
            if isDebugMode {
                print("❌ 保存关卡进度到文件失败: \(error.localizedDescription)")
                print("❌ 错误详情: \(error)")
            }
        }
    }

    private func loadProgressFromFile() -> [PuzzleProgress]? {
        if isDebugMode {
            print("🔍 检查关卡进度文件: \(puzzleProgressURL.path)")
        }

        guard fileManager.fileExists(atPath: puzzleProgressURL.path) else {
            if isDebugMode {
                print("📁 关卡进度文件不存在: \(puzzleProgressURL.path)")
            }
            return nil
        }

        do {
            if isDebugMode {
                print("📖 正在读取关卡进度文件...")
            }
            let data = try Data(contentsOf: puzzleProgressURL)
            if isDebugMode {
                print("📊 文件大小: \(data.count) bytes")
            }

            let progress = try decoder.decode([PuzzleProgress].self, from: data)
            if isDebugMode {
                print("📖 已从文件加载 \(progress.count) 条关卡进度记录")

                // 打印前几个记录的详细信息
                for (index, p) in progress.prefix(3).enumerated() {
                    print("   记录 \(index + 1): stableId=\(p.levelStableId), isCompleted=\(p.isCompleted), bestTime=\(String(describing: p.bestTime)), bestMoves=\(String(describing: p.bestMoves))")
                }
            }

            return progress
        } catch {
            if isDebugMode {
                print("❌ 从文件加载关卡进度失败: \(error.localizedDescription)")
                print("❌ 错误详情: \(error)")
            }

            // 尝试删除损坏的文件
            do {
                try fileManager.removeItem(at: puzzleProgressURL)
                if isDebugMode {
                    print("🗑️ 已删除损坏的关卡进度文件")
                }
            } catch {
                if isDebugMode {
                    print("❌ 无法删除损坏的文件: \(error)")
                }
            }

            return nil
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
            saveUnlockedCategoriesToFile(unlockedCategories)
        }
    }

    func getUnlockedCategories() -> [UUID] {
        // 优先从文件系统加载
        if let categories = loadUnlockedCategoriesFromFile() {
            return categories
        }

        // 回退到UserDefaults（用于迁移）
        guard let strings = userDefaults.array(forKey: Keys.unlockedCategories) as? [String] else {
            return []
        }
        return strings.compactMap { UUID(uuidString: $0) }
    }

    func isCategoryUnlocked(_ categoryId: UUID) -> Bool {
        return getUnlockedCategories().contains(categoryId)
    }

    // MARK: - File-based Categories Storage
    private func saveUnlockedCategoriesToFile(_ categories: [UUID]) {
        do {
            let data = try encoder.encode(categories)
            try data.write(to: unlockedCategoriesURL, options: .atomic)
            if isDebugMode {
                print("✅ 成功保存 \(categories.count) 个解锁分类到文件")
            }
        } catch {
            if isDebugMode {
                print("❌ 保存解锁分类到文件失败: \(error.localizedDescription)")
            }
        }
    }

    private func loadUnlockedCategoriesFromFile() -> [UUID]? {
        guard fileManager.fileExists(atPath: unlockedCategoriesURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: unlockedCategoriesURL)
            let categories = try decoder.decode([UUID].self, from: data)
            return categories
        } catch {
            if isDebugMode {
                print("❌ 从文件加载解锁分类失败: \(error.localizedDescription)")
            }
            return nil
        }
    }

    // MARK: - Achievement States
    func saveAchievementState(_ state: AchievementState) {
        var allStates = getAllAchievementStates()

        if let index = allStates.firstIndex(where: { $0.achievementId == state.achievementId }) {
            allStates[index] = state
        } else {
            allStates.append(state)
        }

        saveAchievementStatesToFile(allStates)

        // 通知UI更新
        objectWillChange.send()
    }

    func getAchievementState(for achievementId: String) -> AchievementState? {
        let allStates = getAllAchievementStates()
        return allStates.first { $0.achievementId == achievementId }
    }

    func getAllAchievementStates() -> [AchievementState] {
        // 优先从文件系统加载
        if let states = loadAchievementStatesFromFile() {
            return states
        }

        // 回退到UserDefaults（用于迁移）
        guard let data = userDefaults.data(forKey: Keys.achievementStates),
              let states = try? decoder.decode([AchievementState].self, from: data) else {
            return []
        }
        return states
    }

    // MARK: - File-based Achievement Storage
    private func saveAchievementStatesToFile(_ states: [AchievementState]) {
        do {
            let data = try encoder.encode(states)
            try data.write(to: achievementStatesURL, options: .atomic)
            if isDebugMode {
                print("✅ 成功保存 \(states.count) 条成就状态记录到文件")
            }
        } catch {
            if isDebugMode {
                print("❌ 保存成就状态到文件失败: \(error.localizedDescription)")
            }
        }
    }

    private func loadAchievementStatesFromFile() -> [AchievementState]? {
        guard fileManager.fileExists(atPath: achievementStatesURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: achievementStatesURL)
            let states = try decoder.decode([AchievementState].self, from: data)
            return states
        } catch {
            if isDebugMode {
                print("❌ 从文件加载成就状态失败: \(error.localizedDescription)")
            }
            return nil
        }
    }

    // MARK: - Reset Functionality
    func resetAllData() {
        // 清空所有游戏进度
        userDefaults.removeObject(forKey: Keys.puzzleProgress)
        userDefaults.removeObject(forKey: Keys.unlockedCategories)
        userDefaults.removeObject(forKey: Keys.achievementStates)

        // 删除文件系统中的数据
        try? fileManager.removeItem(at: puzzleProgressURL)
        try? fileManager.removeItem(at: achievementStatesURL)
        try? fileManager.removeItem(at: unlockedCategoriesURL)

        // 重置应用首次启动状态
        userDefaults.removeObject(forKey: Keys.appFirstLaunch)

        // 通知UI更新
        objectWillChange.send()

        if isDebugMode {
            print("✅ 已重置所有应用数据（包括文件系统数据）")
        }
    }
}
