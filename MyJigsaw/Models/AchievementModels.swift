//
//  AchievementModels.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/15.
//

import Foundation

// MARK: - Achievement Definition
struct AchievementDefinition: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconAssetName: String
    let criterion: AchievementCriterion

    // 预定义成就 - 将在运行时动态生成，以匹配实际的category ID
    static func moduleAchievements(for categories: [PuzzleCategory]) -> [AchievementDefinition] {
        return categories.map { category in
            let achievementId = "ach_category_\(category.id.uuidString)_complete"
            let title: String
            let description: String
            let iconAssetName: String

            switch category.title {
            case "传统年画":
                title = "年画大师"
                description = "完成所有传统年画拼图"
                iconAssetName = "seal.fill"
            case "京剧脸谱":
                title = "脸谱收藏家"
                description = "完成所有京剧脸谱拼图"
                iconAssetName = "theatermasks.fill"
            case "敦煌壁画":
                title = "敦煌探秘者"
                description = "完成所有敦煌壁画拼图"
                iconAssetName = "photo.artframe"
            case "国画":
                title = "国画鉴赏家"
                description = "完成所有国画拼图"
                iconAssetName = "paintpalette.fill"
            default:
                title = "\(category.title)大师"
                description = "完成所有\(category.title)拼图"
                iconAssetName = "seal.fill"
            }

            return AchievementDefinition(
                id: achievementId,
                title: title,
                description: description,
                iconAssetName: iconAssetName,
                criterion: .completeAllLevels(categoryId: category.id.uuidString, difficultyScope: nil, countsOnly: true)
            )
        }
    }

    // 全局有趣成就
    static var globalAchievements: [AchievementDefinition] {
        return [
            // 速度成就
            AchievementDefinition(
                id: "ach_speed_demon",
                title: "闪电侠",
                description: "在2分钟内完成任意关卡",
                iconAssetName: "bolt.fill",
                criterion: .completeLevelInTime(maxTimeSeconds: 120, minDifficulty: nil)
            ),
            AchievementDefinition(
                id: "ach_ultra_fast",
                title: "超速者",
                description: "在1分钟内完成任意关卡",
                iconAssetName: "flame.fill",
                criterion: .completeLevelInTime(maxTimeSeconds: 60, minDifficulty: nil)
            ),

            // 步数成就
            AchievementDefinition(
                id: "ach_efficient",
                title: "高效大师",
                description: "用少于50步完成任意关卡",
                iconAssetName: "target",
                criterion: .completeWithFewMoves(maxMoves: 50)
            ),
            AchievementDefinition(
                id: "ach_minimalist",
                title: "极简主义者",
                description: "用少于30步完成任意关卡",
                iconAssetName: "minus.circle.fill",
                criterion: .completeWithFewMoves(maxMoves: 30)
            ),

            // 连续成就
            AchievementDefinition(
                id: "ach_streak_3",
                title: "连击达人",
                description: "连续完成3个关卡",
                iconAssetName: "3.circle.fill",
                criterion: .completeLevelsInRow(count: 3)
            ),
            AchievementDefinition(
                id: "ach_streak_5",
                title: "连击大师",
                description: "连续完成5个关卡",
                iconAssetName: "5.circle.fill",
                criterion: .completeLevelsInRow(count: 5)
            ),

            // 综合成就
            AchievementDefinition(
                id: "ach_master_collector",
                title: "传统文化大师",
                description: "完成所有分类的所有关卡",
                iconAssetName: "crown.fill",
                criterion: .completeAllCategories
            ),
            AchievementDefinition(
                id: "ach_first_steps",
                title: "初学者",
                description: "完成第一个拼图关卡",
                iconAssetName: "star.fill",
                criterion: .firstTimePlayer
            ),
            AchievementDefinition(
                id: "ach_speed_runner",
                title: "速通大师",
                description: "总游戏时间超过10小时",
                iconAssetName: "clock.fill",
                criterion: .speedRunner(totalTimeSeconds: 36000)
            )
        ]
    }
}

// MARK: - Achievement Criterion
enum AchievementCriterion: Codable, Equatable {
    case completeAllLevels(categoryId: String, difficultyScope: DifficultyScope?, countsOnly: Bool)
    case completeLevelInTime(maxTimeSeconds: Int, minDifficulty: DifficultyScope?)
    case completeWithFewMoves(maxMoves: Int)
    case completeLevelsInRow(count: Int)
    case completeAllCategories
    case firstTimePlayer
    case speedRunner(totalTimeSeconds: Int)

    enum CodingKeys: String, CodingKey {
        case type, categoryId, difficultyScope, countsOnly, maxTimeSeconds, minDifficulty, maxMoves, count, totalTimeSeconds
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .completeAllLevels(let categoryId, let difficultyScope, let countsOnly):
            try container.encode("completeAllLevels", forKey: .type)
            try container.encode(categoryId, forKey: .categoryId)
            try container.encode(difficultyScope, forKey: .difficultyScope)
            try container.encode(countsOnly, forKey: .countsOnly)
        case .completeLevelInTime(let maxTimeSeconds, let minDifficulty):
            try container.encode("completeLevelInTime", forKey: .type)
            try container.encode(maxTimeSeconds, forKey: .maxTimeSeconds)
            try container.encode(minDifficulty, forKey: .minDifficulty)
        case .completeWithFewMoves(let maxMoves):
            try container.encode("completeWithFewMoves", forKey: .type)
            try container.encode(maxMoves, forKey: .maxMoves)
        case .completeLevelsInRow(let count):
            try container.encode("completeLevelsInRow", forKey: .type)
            try container.encode(count, forKey: .count)
        case .completeAllCategories:
            try container.encode("completeAllCategories", forKey: .type)
        case .firstTimePlayer:
            try container.encode("firstTimePlayer", forKey: .type)
        case .speedRunner(let totalTimeSeconds):
            try container.encode("speedRunner", forKey: .type)
            try container.encode(totalTimeSeconds, forKey: .totalTimeSeconds)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "completeAllLevels":
            let categoryId = try container.decode(String.self, forKey: .categoryId)
            let difficultyScope = try container.decodeIfPresent(DifficultyScope.self, forKey: .difficultyScope)
            let countsOnly = try container.decode(Bool.self, forKey: .countsOnly)
            self = .completeAllLevels(categoryId: categoryId, difficultyScope: difficultyScope, countsOnly: countsOnly)
        case "completeLevelInTime":
            let maxTimeSeconds = try container.decode(Int.self, forKey: .maxTimeSeconds)
            let minDifficulty = try container.decodeIfPresent(DifficultyScope.self, forKey: .minDifficulty)
            self = .completeLevelInTime(maxTimeSeconds: maxTimeSeconds, minDifficulty: minDifficulty)
        case "completeWithFewMoves":
            let maxMoves = try container.decode(Int.self, forKey: .maxMoves)
            self = .completeWithFewMoves(maxMoves: maxMoves)
        case "completeLevelsInRow":
            let count = try container.decode(Int.self, forKey: .count)
            self = .completeLevelsInRow(count: count)
        case "completeAllCategories":
            self = .completeAllCategories
        case "firstTimePlayer":
            self = .firstTimePlayer
        case "speedRunner":
            let totalTimeSeconds = try container.decode(Int.self, forKey: .totalTimeSeconds)
            self = .speedRunner(totalTimeSeconds: totalTimeSeconds)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown criterion type")
        }
    }
}

// MARK: - Difficulty Scope
enum DifficultyScope: String, Codable {
    case easy
    case standard
    case hard
    case any
}

// MARK: - Achievement State
struct AchievementState: Identifiable, Codable {
    let achievementId: String
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progressCompleted: Int
    var progressTotal: Int
    var lastEvaluatedAt: Date

    var id: String { achievementId }

    init(achievementId: String) {
        self.achievementId = achievementId
        self.isUnlocked = false
        self.unlockedAt = nil
        self.progressCompleted = 0
        self.progressTotal = 0
        self.lastEvaluatedAt = Date()
    }

    mutating func updateProgress(completed: Int, total: Int) {
        self.progressCompleted = completed
        self.progressTotal = total
        self.lastEvaluatedAt = Date()

        // 如果进度完成且未解锁，则解锁成就
        if completed == total && total > 0 && !isUnlocked {
            isUnlocked = true
            unlockedAt = Date()
        }
    }
}

// MARK: - Achievement View Data
struct AchievementViewData: Identifiable {
    let achievement: AchievementDefinition
    let state: AchievementState

    var id: String { achievement.id }

    var progressPercentage: Double {
        guard state.progressTotal > 0 else { return 0 }
        return Double(state.progressCompleted) / Double(state.progressTotal)
    }

    var isCompleted: Bool {
        state.isUnlocked
    }
}
