//
//  PuzzleModels.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import Foundation

// MARK: - Puzzle Category
struct PuzzleCategory: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let coverImageName: String
    let sortOrder: Int
    
    init(id: UUID = UUID(), title: String, description: String, coverImageName: String, sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.description = description
        self.coverImageName = coverImageName
        self.sortOrder = sortOrder
    }
}

// MARK: - Puzzle Level
struct PuzzleLevel: Identifiable, Codable {
    let id: UUID
    let categoryId: UUID
    let title: String
    let previewImageName: String
    let sourceInfo: String
    let gridSize: Int // 3 for 3x3, 4 for 4x4, etc.
    let difficulty: PuzzleDifficulty
    var isLocked: Bool
    
    init(id: UUID = UUID(), categoryId: UUID, title: String, previewImageName: String, sourceInfo: String, gridSize: Int, difficulty: PuzzleDifficulty, isLocked: Bool = true) {
        self.id = id
        self.categoryId = categoryId
        self.title = title
        self.previewImageName = previewImageName
        self.sourceInfo = sourceInfo
        self.gridSize = gridSize
        self.difficulty = difficulty
        self.isLocked = isLocked
    }
}

// MARK: - Puzzle Difficulty
enum PuzzleDifficulty: String, CaseIterable, Codable {
    case easy = "简单"
    case standard = "标准"
    case hard = "困难"
    
    var gridSize: Int {
        switch self {
        case .easy:
            return 3
        case .standard:
            return 4
        case .hard:
            return 6
        }
    }
}

// MARK: - Puzzle Piece
struct PuzzlePiece: Identifiable, Codable {
    let id: UUID
    let index: Int
    let imageCropRect: CGRect
    /// 目标中心点（单位：棋盘内像素坐标）
    let targetPosition: CGPoint
    /// 当前中心点（单位：棋盘内像素坐标）
    var currentPosition: CGPoint
    var isLocked: Bool
    
    init(id: UUID = UUID(), index: Int, imageCropRect: CGRect, targetPosition: CGPoint, currentPosition: CGPoint, isLocked: Bool = false) {
        self.id = id
        self.index = index
        self.imageCropRect = imageCropRect
        self.targetPosition = targetPosition
        self.currentPosition = currentPosition
        self.isLocked = isLocked
    }
}

// MARK: - Puzzle Progress
struct PuzzleProgress: Identifiable, Codable {
    let id: UUID
    let levelId: UUID
    var isCompleted: Bool
    var bestTime: TimeInterval? // in seconds
    var bestMoves: Int?
    var lastPlayedAt: Date
    
    init(id: UUID = UUID(), levelId: UUID, isCompleted: Bool = false, bestTime: TimeInterval? = nil, bestMoves: Int? = nil, lastPlayedAt: Date = Date()) {
        self.id = id
        self.levelId = levelId
        self.isCompleted = isCompleted
        self.bestTime = bestTime
        self.bestMoves = bestMoves
        self.lastPlayedAt = lastPlayedAt
    }
}

// MARK: - App Settings
struct AppSettings: Codable {
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var showGuideOverlay: Bool
    var reduceMotionOverride: Bool
    var timerEnabled: Bool
    
    init(soundEnabled: Bool = true, hapticsEnabled: Bool = true, showGuideOverlay: Bool = false, reduceMotionOverride: Bool = false, timerEnabled: Bool = false) {
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.showGuideOverlay = showGuideOverlay
        self.reduceMotionOverride = reduceMotionOverride
        self.timerEnabled = timerEnabled
    }
}
