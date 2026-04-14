//
//  ContentManager.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import Foundation
import Combine

// MARK: - Content Manager
class ContentManager: ObservableObject {
    static let shared = ContentManager()

    @Published var categories: [PuzzleCategory] = []
    @Published var levels: [PuzzleLevel] = []
    @Published var microAnnotationPacks: [MicroAnnotationPack] = []

    private init() {
        loadInitialContent()
        loadMicroAnnotations()
    }
    
    // MARK: - Content Loading
    private func loadInitialContent() {
        // In a real app, this would load from a bundled JSON file or remote API
        // For now, we'll create some sample content
        
        // Create categories
        categories = [
            PuzzleCategory(
                title: "民居",
                description: "青砖黛瓦、粉墙飞檐的传统民居建筑拼图",
                coverImageName: "category_minju",
                sortOrder: 1
            ),
            PuzzleCategory(
                title: "官府",
                description: "庄严肃穆、规制方正的传统官府衙门拼图",
                coverImageName: "category_guanfu",
                sortOrder: 2
            ),
            PuzzleCategory(
                title: "皇宫",
                description: "金碧辉煌、巍峨壮丽的皇家宫殿建筑拼图",
                coverImageName: "category_huanggong",
                sortOrder: 3
            ),
            PuzzleCategory(
                title: "桥梁",
                description: "拱桥卧波、廊桥横卧的传统桥梁建筑拼图",
                coverImageName: "category_qiaoliang",
                sortOrder: 4
            ),
            PuzzleCategory(
                id: UGCManager.ugcCategoryId,
                title: "自制拼图",
                description: "上传你的照片，创建专属拼图",
                coverImageName: "photo.fill", // 使用系统图标作为封面
                sortOrder: 5,
                isUGC: true
            )
        ]
        
        // Create sample levels for each category
        levels = createSampleLevels()
    }

    private func loadMicroAnnotations() {
        guard let url = Bundle.main.url(forResource: "micro_notes", withExtension: "json") else {
            print("❌ 找不到 micro_notes.json 文件")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            microAnnotationPacks = try decoder.decode([MicroAnnotationPack].self, from: data)
            //print("✅ 成功加载 \(microAnnotationPacks.count) 个微注释包")
        } catch {
            //print("❌ 加载微注释数据失败: \(error.localizedDescription)")
        }
    }
    
    private func createSampleLevels() -> [PuzzleLevel] {
        var levels: [PuzzleLevel] = []
        
        // Sample levels for each category
        for (index, category) in categories.enumerated() {
            // Create 3 levels per category with different difficulties
            for difficulty in PuzzleDifficulty.allCases {
                // 特殊处理：各分类使用特定图片
                var previewImageName = "preview_\(index)_\(difficulty.rawValue)"
                if difficulty == .easy {
                    if category.title == "民居" {
                        previewImageName = "minju_01"
                    } else if category.title == "官府" {
                        previewImageName = "guanfu_01"
                    }
                    else if category.title == "皇宫" {
                        previewImageName = "huanggong_01"
                    }
                    else if category.title == "桥梁" {
                        previewImageName = "qiaoliang_01"
                    }
                }
                else if difficulty == .standard {
                    if category.title == "民居" {
                        previewImageName = "minju_02"
                    } else if category.title == "官府" {
                        previewImageName = "guanfu_02"
                    }
                    else if category.title == "皇宫" {
                        previewImageName = "huanggong_02"
                    }
                    else if category.title == "桥梁" {
                        previewImageName = "qiaoliang_02"
                    }
                }
                else{
                    if category.title == "民居" {
                        previewImageName = "minju_03"
                    } else if category.title == "官府" {
                        previewImageName = "guanfu_03"
                    }
                    else if category.title == "皇宫" {
                        previewImageName = "huanggong_03"
                    }
                    else if category.title == "桥梁" {
                        previewImageName = "qiaoliang_03"
                    }
                }
                // 创建稳定的关卡标识符：基于分类名称和难度
                let stableId = "\(category.title)_\(difficulty.rawValue)"

                let level = PuzzleLevel(
                    categoryId: category.id,
                    title: "\(category.title) - \(difficulty.rawValue)",
                    previewImageName: previewImageName,
                    sourceInfo: "来源：\(category.title)示例图片",
                    gridSize: difficulty.gridSize,
                    difficulty: difficulty,
                    //isLocked: index > 0 // Unlock first category only
                    isLocked: false,
                    stableId: stableId
                )
                levels.append(level)
            }
        }
        
        return levels
    }
    
    // MARK: - Content Access
    func getLevels(for categoryId: UUID) -> [PuzzleLevel] {
        if categoryId == UGCManager.ugcCategoryId {
            // 返回UGC关卡
            return UGCManager.shared.ugcPuzzles.map { $0.toPuzzleLevel() }
        } else {
            // 返回普通关卡
            return levels.filter { $0.categoryId == categoryId }
        }
    }

    func getLevels(forCategoryId categoryId: String) -> [PuzzleLevel] {
        // 根据字符串ID获取关卡（用于成就系统）
        if let uuid = UUID(uuidString: categoryId) {
            return getLevels(for: uuid)
        }
        return []
    }

    func getUGCPuzzle(for levelId: UUID) -> UGCPuzzle? {
        return UGCManager.shared.ugcPuzzles.first { $0.id == levelId }
    }
    
    func getCategory(for categoryId: UUID) -> PuzzleCategory? {
        return categories.first { $0.id == categoryId }
    }
    
    func getLevel(for levelId: UUID) -> PuzzleLevel? {
        return levels.first { $0.id == levelId }
    }

    func getMicroAnnotationPack(for artworkId: String) -> MicroAnnotationPack? {
        return microAnnotationPacks.first { $0.artworkId == artworkId }
    }

    func getMicroAnnotationPack(for level: PuzzleLevel) -> MicroAnnotationPack? {
        // 根据关卡的预览图片名称匹配微注释包
        // 例如：预览图片名为 "nianhua_01"，对应的微注释包ID为 "nianhua_01_pack"
        let artworkId = level.previewImageName
        return getMicroAnnotationPack(for: artworkId)
    }
    
    // MARK: - Content Management
    func unlockLevel(_ level: PuzzleLevel) {
        if let index = levels.firstIndex(where: { $0.id == level.id }) {
            levels[index].isLocked = false
        }
    }
    
    func unlockNextLevel(after completedLevel: PuzzleLevel) {
        // Find the next level in the same category
        guard categories.firstIndex(where: { $0.id == completedLevel.categoryId }) != nil,
              levels.firstIndex(where: { $0.id == completedLevel.id }) != nil else {
            return
        }
        
        let categoryLevels = getLevels(for: completedLevel.categoryId).sorted { $0.difficulty.rawValue < $1.difficulty.rawValue }
        
        if let currentIndex = categoryLevels.firstIndex(where: { $0.id == completedLevel.id }),
           currentIndex < categoryLevels.count - 1 {
            let nextLevel = categoryLevels[currentIndex + 1]
            unlockLevel(nextLevel)
        }
    }
}
