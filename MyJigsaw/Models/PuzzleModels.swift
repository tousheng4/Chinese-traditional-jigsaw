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
    let isUGC: Bool // 是否为用户自定义分类

    init(id: UUID = UUID(), title: String, description: String, coverImageName: String, sortOrder: Int = 0, isUGC: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.coverImageName = coverImageName
        self.sortOrder = sortOrder
        self.isUGC = isUGC
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
    /// 是否计入模块成就（默认true）
    let countsForModuleAchievement: Bool
    /// 稳定的关卡标识符，用于持久化匹配
    let stableId: String

    init(id: UUID = UUID(), categoryId: UUID, title: String, previewImageName: String, sourceInfo: String, gridSize: Int, difficulty: PuzzleDifficulty, isLocked: Bool = true, countsForModuleAchievement: Bool = true, stableId: String? = nil) {
        self.id = id
        self.categoryId = categoryId
        self.title = title
        self.previewImageName = previewImageName
        self.sourceInfo = sourceInfo
        self.gridSize = gridSize
        self.difficulty = difficulty
        self.isLocked = isLocked
        self.countsForModuleAchievement = countsForModuleAchievement
        // 如果没有提供稳定的ID，则使用categoryId和difficulty的组合
        self.stableId = stableId ?? "\(categoryId.uuidString)_\(difficulty.rawValue)"
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
    /// 使用稳定的关卡标识符而不是UUID
    let levelStableId: String
    var isCompleted: Bool
    var bestTime: TimeInterval? // in seconds
    var bestMoves: Int?
    var lastPlayedAt: Date

    init(id: UUID = UUID(), levelStableId: String, isCompleted: Bool = false, bestTime: TimeInterval? = nil, bestMoves: Int? = nil, lastPlayedAt: Date = Date()) {
        self.id = id
        self.levelStableId = levelStableId
        self.isCompleted = isCompleted
        self.bestTime = bestTime
        self.bestMoves = bestMoves
        self.lastPlayedAt = lastPlayedAt
    }

    // 兼容性构造函数，从levelId转换
    init(from levelId: UUID, isCompleted: Bool = false, bestTime: TimeInterval? = nil, bestMoves: Int? = nil, lastPlayedAt: Date = Date()) {
        self.id = UUID()
        self.levelStableId = levelId.uuidString // 临时兼容
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

// MARK: - UGC Puzzle (User Generated Content)
struct UGCPuzzle: Identifiable, Codable {
    let id: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    let imageAssetPath: String // 预处理主图存储路径
    let thumbnailPath: String  // 缩略图存储路径
    let config: PuzzleConfig
    let style: UGCStyleConfig // 模板信息

    init(id: UUID = UUID(), title: String, imageAssetPath: String, thumbnailPath: String, config: PuzzleConfig, style: UGCStyleConfig = UGCStyleConfig()) {
        self.id = id
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.imageAssetPath = imageAssetPath
        self.thumbnailPath = thumbnailPath
        self.config = config
        self.style = style
    }

    // 转换为PuzzleLevel以便在游戏中使用
    func toPuzzleLevel() -> PuzzleLevel {
        let stableId = "ugc_\(id.uuidString)" // UGC关卡使用固定标识符

        return PuzzleLevel(
            id: id, // 关键：UGC关卡必须使用固定id，否则无法映射到缩略图/主图/进度
            categoryId: UGCManager.ugcCategoryId,
            title: title,
            previewImageName: "ugc_\(id.uuidString)", // 使用特殊标识符
            sourceInfo: "用户自制拼图",
            gridSize: config.gridSize,
            difficulty: config.difficulty,
            isLocked: false,
            countsForModuleAchievement: false, // 自制关卡不计入成就
            stableId: stableId
        )
    }
}

// MARK: - Puzzle Configuration
struct PuzzleConfig: Codable {
    let gridSize: Int
    let allowRotation: Bool
    let shuffleMode: ShuffleMode
    let snapStrength: SnapStrength

    var difficulty: PuzzleDifficulty {
        switch gridSize {
        case 3: return .easy
        case 4: return .standard
        case 6: return .hard
        default: return .standard
        }
    }

    init(gridSize: Int = 4, allowRotation: Bool = false, shuffleMode: ShuffleMode = .scatter, snapStrength: SnapStrength = .medium) {
        self.gridSize = gridSize
        self.allowRotation = allowRotation
        self.shuffleMode = shuffleMode
        self.snapStrength = snapStrength
    }
}

// MARK: - Shuffle Mode
enum ShuffleMode: String, Codable, CaseIterable {
    case scatter = "散布"
    case stack = "堆叠"
}

// MARK: - Snap Strength
enum SnapStrength: String, Codable, CaseIterable {
    case weak = "弱"
    case medium = "中"
    case strong = "强"
}

// MARK: - UGC Style Configuration
struct UGCStyleConfig: Codable {
    let paperTexture: PaperTexture
    let borderStyle: BorderStyle
    let showSeal: Bool
    let sealText: String

    init(paperTexture: PaperTexture = .plain, borderStyle: BorderStyle = .none, showSeal: Bool = false, sealText: String = "") {
        self.paperTexture = paperTexture
        self.borderStyle = borderStyle
        self.showSeal = showSeal
        self.sealText = sealText
    }
}

// MARK: - Paper Texture
enum PaperTexture: String, Codable, CaseIterable {
    case plain = "素纸"
    case ricePaper = "宣纸"
    case silk = "绢本"
}

// MARK: - Border Style
enum BorderStyle: String, Codable, CaseIterable {
    case none = "无边框"
    case scroll = "卷轴"
    case frame = "画框"
    case album = "册页"
}

// MARK: - UGC Progress
struct UGCProgress: Identifiable, Codable {
    let id: UUID
    let puzzleId: UUID
    var isCompleted: Bool
    var bestTime: TimeInterval?
    var bestMoves: Int?
    var lastPlayedAt: Date?

    init(puzzleId: UUID, isCompleted: Bool = false, bestTime: TimeInterval? = nil, bestMoves: Int? = nil, lastPlayedAt: Date? = nil) {
        self.id = UUID()
        self.puzzleId = puzzleId
        self.isCompleted = isCompleted
        self.bestTime = bestTime
        self.bestMoves = bestMoves
        self.lastPlayedAt = lastPlayedAt
    }
}

// MARK: - Micro Annotation Models
/// 微注释包 - 对应一个作品的完整注释信息
struct MicroAnnotationPack: Identifiable, Codable {
    let id: String // 通常与作品ID相同
    let artworkId: String
    let microNotes: [MicroNote]
    let detailSections: [DetailSection]

    var primaryNote: MicroNote? {
        microNotes.filter { $0.priority == 0 }.first ?? microNotes.first
    }

    var secondaryNote: MicroNote? {
        let nonPrimaryNotes = microNotes.filter { $0.priority != 0 }
        return nonPrimaryNotes.randomElement()
    }
}

/// 微注释 - 简短的知识点提示
struct MicroNote: Identifiable, Codable {
    let id: String
    let text: String // 18-34 字的简短注释
    let priority: Int // 0=最重要的，1=次要的，2=辅助的
    let tone: NoteTone? // 入门/进阶
    let relatedHotspotIds: [String]? // 关联的画面热点ID（预留）

    enum NoteTone: String, Codable {
        case beginner = "入门"
        case advanced = "进阶"
    }
}

/// 详情段落 - 扩展页的完整内容
struct DetailSection: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let references: [String]? // 可选的参考资料
}
