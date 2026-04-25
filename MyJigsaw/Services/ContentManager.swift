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
        
        // Sample levels for each category (skip UGC)
        for (index, category) in categories.enumerated() {
            guard !category.isUGC else { continue }
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
        
        // 部件拼图关卡：挂到对应的普通分类下
        let bridgeCategory = categories.first(where: { $0.title == "桥梁" })!
        let zhaozhou = PuzzleLevel(
            id: UUID(uuidString: "BB000001-0000-0000-0000-000000000001")!,
            categoryId: bridgeCategory.id,
            title: "赵州桥",
            previewImageName: "zhaozhou_preview",
            sourceInfo: "隋朝 · 公元595—605年，李春设计建造，现存最古老的石拱桥",
            gridSize: 1,
            difficulty: .standard,
            isLocked: false,
            countsForModuleAchievement: false,
            stableId: "component_zhaozhou_bridge",
            puzzleMode: .component,
            componentPieces: [
                ComponentPieceDefinition(id: "left_arch",  imageName: "zhaozhou_left_arch",  name: "左小拱",  description: "主拱左侧的小拱券，减轻桥身自重，同时扩大过洪面积，是敞肩拱的核心创新。",  targetCenter: CGPoint(x: 814    / 1890, y: 897   / 1417)),
                ComponentPieceDefinition(id: "left_pier",  imageName: "zhaozhou_left_pier",  name: "左桥台",  description: "左侧桥台承受主拱传来的水平推力，以精密干砌石块砌筑，不用灰浆，稳固千年。", targetCenter: CGPoint(x: 286.5  / 1890, y: 1085  / 1417)),
                ComponentPieceDefinition(id: "main_arch",  imageName: "zhaozhou_main_arch",  name: "主拱",    description: "桥梁核心结构，净跨37米，由28道独立拱圈并列砌成，是当时世界最大的石拱桥。",   targetCenter: CGPoint(x: 1125.5 / 1890, y: 939.5 / 1417)),
                ComponentPieceDefinition(id: "right_arch", imageName: "zhaozhou_right_arch", name: "右小拱",  description: "与左小拱对称，两侧小拱共同将主拱自重减轻约15%，并在洪水期加速泄洪。",         targetCenter: CGPoint(x: 1441.5 / 1890, y: 719.5 / 1417)),
                ComponentPieceDefinition(id: "right_pier", imageName: "zhaozhou_right_pier", name: "右桥台",  description: "右侧桥台与左桥台共同形成稳定支撑，两端桥台深埋地基，抵抗拱脚外推力。",         targetCenter: CGPoint(x: 1789   / 1890, y: 770.5 / 1417)),
                ComponentPieceDefinition(id: "deck",       imageName: "zhaozhou_deck",       name: "桥面",    description: "宽约9米，可供两辆马车并行，纵向条石铺砌，历经1400年车马碾压仍保持平整。",      targetCenter: CGPoint(x: 965    / 1890, y: 711   / 1417)),
            ],
            canvasSize: CGSize(width: 1890, height: 1417)
        )
        levels.append(zhaozhou)

        let palaceCategory = categories.first(where: { $0.title == "皇宫" })!
        let gugong = PuzzleLevel(
            id: UUID(uuidString: "CC000001-0000-0000-0000-000000000001")!,
            categoryId: palaceCategory.id,
            title: "故宫",
            previewImageName: "gugong_preview",
            sourceInfo: "明清两朝皇宫，始建于明永乐四年（1406年），世界现存规模最大的古代宫殿建筑群",
            gridSize: 1,
            difficulty: .standard,
            isLocked: false,
            countsForModuleAchievement: false,
            stableId: "component_gugong_palace",
            puzzleMode: .component,
            componentPieces: [
                ComponentPieceDefinition(id: "roof",       imageName: "gugong_roof",       name: "屋顶",       description: "重檐庑殿顶，最高等级的屋顶形式，黄色琉璃瓦象征皇权，正脊两端饰鸱吻，垂脊置走兽。",       targetCenter: CGPoint(x: 1050   / 2048, y: 1154   / 2048), zIndex: 6),
                ComponentPieceDefinition(id: "chiwen",     imageName: "gugong_chiwen",     name: "鸱吻和走兽", description: "鸱吻立于正脊两端，传说能镇火避灾；垂脊上的走兽数量越多，建筑等级越高，太和殿共有十只。", targetCenter: CGPoint(x: 1055.5 / 2048, y: 1133.5 / 2048), zIndex: 5),
                ComponentPieceDefinition(id: "windows",    imageName: "gugong_windows",    name: "门窗",       description: "隔扇门窗以楠木精雕细琢，菱花纹格心象征吉祥，朱红油漆与金色装饰彰显皇家气派。",           targetCenter: CGPoint(x: 1081.5 / 2048, y: 1121   / 2048), zIndex: 4),
                ComponentPieceDefinition(id: "balustrade", imageName: "gugong_balustrade", name: "汉白玉栏杆", description: "三层汉白玉台基四周环绕云龙纹栏杆，每根望柱柱头雕刻云龙或凤凰，雨水从螭首排出。",         targetCenter: CGPoint(x: 983.5  / 2048, y: 1302   / 2048), zIndex: 3),
                ComponentPieceDefinition(id: "wall",       imageName: "gugong_wall",       name: "墙壁",       description: "朱红宫墙以糯米浆与石灰混合砌筑，厚约1米，既防火又隔音，历经六百年仍坚固如初。",           targetCenter: CGPoint(x: 1135.5 / 2048, y: 1431   / 2048), zIndex: 2),
                ComponentPieceDefinition(id: "base",       imageName: "gugong_base",       name: "汉白玉底座", description: "三层须弥座台基高达8.13米，全部用汉白玉砌成，每层台基边缘均有螭首排水，气势恢宏。",         targetCenter: CGPoint(x: 1016.5 / 2048, y: 1331   / 2048), zIndex: 1),
                ComponentPieceDefinition(id: "interior",   imageName: "gugong_interior",   name: "内部结构",   description: "以楠木为主要承重构件，抬梁式木构架体系，梁架之间以榫卯连接，无需一根铁钉。",               targetCenter: CGPoint(x: 1049   / 2048, y: 1104   / 2048), zIndex: 0),
            ],
            canvasSize: CGSize(width: 2048, height: 2048)
        )
        levels.append(gugong)

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
