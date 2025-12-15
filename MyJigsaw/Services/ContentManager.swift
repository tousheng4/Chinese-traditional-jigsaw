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
    
    private init() {
        loadInitialContent()
    }
    
    // MARK: - Content Loading
    private func loadInitialContent() {
        // In a real app, this would load from a bundled JSON file or remote API
        // For now, we'll create some sample content
        
        // Create categories
        categories = [
            PuzzleCategory(
                title: "传统年画",
                description: "吉祥寓意、节俗叙事的传统年画拼图",
                coverImageName: "category_nianhua",
                sortOrder: 1
            ),
            PuzzleCategory(
                title: "京剧脸谱",
                description: "角色谱系、色彩象征的京剧脸谱拼图",
                coverImageName: "category_lianpu",
                sortOrder: 2
            ),
            PuzzleCategory(
                title: "敦煌壁画",
                description: "线描与设色、飞天与供养人题材的敦煌壁画拼图",
                coverImageName: "category_dunhuang",
                sortOrder: 3
            ),
            PuzzleCategory(
                title: "国画",
                description: "山水、花鸟、人物等传统国画拼图",
                coverImageName: "category_guohua",
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
    
    private func createSampleLevels() -> [PuzzleLevel] {
        var levels: [PuzzleLevel] = []
        
        // Sample levels for each category
        for (index, category) in categories.enumerated() {
            // Create 3 levels per category with different difficulties
            for difficulty in PuzzleDifficulty.allCases {
                // 特殊处理：京剧脸谱和传统年画的第一关使用特定图片
                var previewImageName = "preview_\(index)_\(difficulty.rawValue)"
                if difficulty == .easy {
                    if category.title == "京剧脸谱" {
                        previewImageName = "lianpu_01"
                    } else if category.title == "传统年画" {
                        previewImageName = "nianhua_01"
                    }
                    else if category.title == "敦煌壁画" {
                        previewImageName = "dunhuang_01"
                    }
                    else if category.title == "国画" {
                        previewImageName = "guohua_01"
                    }
                }
                else if difficulty == .standard {
                    if category.title == "京剧脸谱" {
                        previewImageName = "lianpu_02"
                    } else if category.title == "传统年画" {
                        previewImageName = "nianhua_02"
                    }
                    else if category.title == "敦煌壁画" {
                        previewImageName = "dunhuang_02"
                    }
                    else if category.title == "国画" {
                        previewImageName = "guohua_02"
                    }
                }
                else{
                    if category.title == "京剧脸谱" {
                        previewImageName = "lianpu_03"
                    } else if category.title == "传统年画" {
                        previewImageName = "nianhua_03"
                    }
                    else if category.title == "敦煌壁画" {
                        previewImageName = "dunhuang_03"
                    }
                    else if category.title == "国画" {
                        previewImageName = "guohua_03"
                    }
                }
                let level = PuzzleLevel(
                    categoryId: category.id,
                    title: "\(category.title) - \(difficulty.rawValue)",
                    previewImageName: previewImageName,
                    sourceInfo: "来源：\(category.title)示例图片",
                    gridSize: difficulty.gridSize,
                    difficulty: difficulty,
                    //isLocked: index > 0 // Unlock first category only
                    isLocked: false
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
