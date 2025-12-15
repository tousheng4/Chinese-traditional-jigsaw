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
}

// MARK: - Achievement Criterion
enum AchievementCriterion: Codable, Equatable {
    case completeAllLevels(categoryId: String, difficultyScope: DifficultyScope?, countsOnly: Bool)

    enum CodingKeys: String, CodingKey {
        case type, categoryId, difficultyScope, countsOnly
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .completeAllLevels(let categoryId, let difficultyScope, let countsOnly):
            try container.encode("completeAllLevels", forKey: .type)
            try container.encode(categoryId, forKey: .categoryId)
            try container.encode(difficultyScope, forKey: .difficultyScope)
            try container.encode(countsOnly, forKey: .countsOnly)
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
