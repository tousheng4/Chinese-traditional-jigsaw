//
//  CategoryView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI

struct CategoryView: View {
    let category: PuzzleCategory
    @StateObject private var contentManager = ContentManager.shared
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var ugcManager = UGCManager.shared
    private let storyManager = StoryManager.shared

    @State private var showDIYCreation = false
    @State private var selectedMode: PuzzleMode = .grid

    private var allLevels: [PuzzleLevel] {
        contentManager.getLevels(for: category.id)
    }

    private var orderedLevels: [PuzzleLevel] {
        if category.isUGC {
            return allLevels
        }
        return storyManager.orderedLevels(for: category, from: contentManager)
    }

    private var hasComponentLevels: Bool {
        allLevels.contains(where: { $0.puzzleMode == .component })
    }

    private var filteredLevels: [PuzzleLevel] {
        orderedLevels.filter { $0.puzzleMode == selectedMode }
    }

    private var storyChapter: StoryChapter? {
        storyManager.chapter(for: category)
    }

    private var storyProgress: (completed: Int, total: Int) {
        storyManager.chapterProgress(
            for: category,
            contentManager: contentManager,
            persistenceManager: persistenceManager
        )
    }

    private var isCategoryUnlocked: Bool {
        storyManager.isChapterUnlocked(
            category,
            among: contentManager.categories,
            contentManager: contentManager,
            persistenceManager: persistenceManager
        )
    }

    var body: some View {
        ZStack {
            Color.traditional.paper.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 16) {
                    headerSection

                    if category.isUGC {
                        ugcSection
                    } else {
                        if hasComponentLevels {
                            modePicker
                                .padding(.horizontal)
                        }
                        levelsGrid
                    }
                }
                .padding()
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showDIYCreation) {
            DIYCreationView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        Group {
            if category.isUGC {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 56))
                        .foregroundColor(.traditional.vermilion)

                    Text(category.description)
                        .traditionalSubheadline()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                VStack(spacing: 16) {
                    Image(category.coverImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .cornerRadius(12)
                        .clipped()

                    if let storyChapter {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("\(storyChapter.chapterLabel) · \(storyChapter.chapterTitle)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.traditional.vermilion)

                                Spacer()

                                Text("已修复 \(storyProgress.completed)/\(storyProgress.total)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.traditional.ink.opacity(0.65))
                            }

                            Text(category.description)
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.traditional.ink)
                                .lineSpacing(4)

                            Text(storyChapter.summary)
                                .font(.system(size: 14, design: .serif))
                                .foregroundColor(.traditional.ink.opacity(0.75))
                                .lineSpacing(4)

                            Divider()
                                .overlay(Color.traditional.ocher.opacity(0.25))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("本章目标")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.traditional.ink.opacity(0.58))
                                Text(storyChapter.objective)
                                    .font(.system(size: 14, design: .serif))
                                    .foregroundColor(.traditional.ink.opacity(0.82))
                                    .lineSpacing(4)
                            }
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.88))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.traditional.ocher.opacity(0.24), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - UGC Section
    private var ugcSection: some View {
        VStack(spacing: 20) {
            // 新建拼图按钮
            Button(action: {
                showDIYCreation = true
            }) {
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.traditional.vermilion)

                    Text("新建拼图")
                        .font(.qianTuBiFeng(size: 17))
                        .foregroundColor(.traditional.ink)

                    Text("上传你的照片，创建专属拼图")
                        .font(.qianTuBiFeng(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(Color.white.opacity(0.8))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8)
            }

            // UGC关卡列表
            if !allLevels.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("我的拼图")
                        .font(.qianTuBiFeng(size: 22))
                        .foregroundColor(.traditional.ink)

                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 16)
                    ], spacing: 16) {
                        ForEach(allLevels) { level in
                            NavigationLink(destination: PuzzleGameView(level: level)) {
                                UGCLevelCard(level: level, ugcPuzzle: contentManager.getUGCPuzzle(for: level.id))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("还没有自制拼图")
                        .font(.qianTuBiFeng(size: 17))
                        .foregroundColor(.secondary)

                    Text("点击上方按钮开始创建你的第一幅拼图")
                        .font(.qianTuBiFeng(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
            }
        }
    }

    // MARK: - Mode Picker
    private var modePicker: some View {
        HStack(spacing: 0) {
            modeButton("经典拼图", mode: .grid)
            modeButton("部件拼图", mode: .component)
        }
        .background(Color.traditional.ocher.opacity(0.08))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.traditional.ocher.opacity(0.4), lineWidth: 1))
        .animation(.easeInOut(duration: 0.18), value: selectedMode)
    }

    private func modeButton(_ title: String, mode: PuzzleMode) -> some View {
        Button(action: { selectedMode = mode }) {
            Text(title)
                .font(.qianTuBiFeng(size: 15))
                .foregroundColor(selectedMode == mode ? .white : .traditional.ink.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(selectedMode == mode ? Color.traditional.vermilion : Color.clear)
                .cornerRadius(9)
        }
        .padding(3)
    }

    // MARK: - Levels Grid
    private var levelsGrid: some View {
        Group {
            if filteredLevels.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.traditional.ocher.opacity(0.5))
                    Text("暂无\(selectedMode == .component ? "部件" : "经典")拼图")
                        .font(.qianTuBiFeng(size: 15))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredLevels) { level in
                        NavigationLink(destination: PuzzleGameView(level: level)) {
                            LevelCard(
                                level: level,
                                pageLabel: storyManager.pageLabel(for: level, in: category, from: contentManager),
                                isUnlocked: isLevelUnlocked(level),
                                lockReason: levelLockReason(level)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!isLevelUnlocked(level))
                    }
                }
            }
        }
    }

    private func isLevelUnlocked(_ level: PuzzleLevel) -> Bool {
        storyManager.isLevelUnlocked(
            level,
            in: category,
            among: contentManager.categories,
            contentManager: contentManager,
            persistenceManager: persistenceManager
        )
    }

    private func levelLockReason(_ level: PuzzleLevel) -> String? {
        storyManager.levelLockReason(
            level,
            in: category,
            among: contentManager.categories,
            contentManager: contentManager,
            persistenceManager: persistenceManager
        )
    }

    private var categoryNameIcon: String {
        switch category.title {
        case "民居":
            return "house.fill"
        case "官府":
            return "building.columns.fill"
        case "皇宫":
            return "crown.fill"
        case "桥梁":
            return "road.lanes"
        default:
            return "photo.fill"
        }
    }
}

// MARK: - UGC Level Card
struct UGCLevelCard: View {
    let level: PuzzleLevel
    let ugcPuzzle: UGCPuzzle?
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var ugcManager = UGCManager.shared

    @State private var showDeleteAlert = false

    private var progress: PuzzleProgress {
        persistenceManager.getGameProgress(forStableId: level.stableId)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .center) {
                    if let ugcPuzzle = ugcPuzzle, let thumbnail = ugcManager.getThumbnail(for: ugcPuzzle) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: .infinity, height: 120, alignment: .center)
                            .cornerRadius(12)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: .infinity, height: 120)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }

                    // 删除按钮
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
                .frame(height: 120)

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.system(.headline, design: .serif))
                        .fontWeight(.medium)
                        .foregroundColor(.traditional.ink)
                        .lineLimit(1)

                    HStack {
                        Text(level.difficulty.rawValue)
                            .font(.qianTuBiFeng(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(difficultyColor.opacity(0.1))
                            .foregroundColor(difficultyColor)
                            .cornerRadius(4)

                        Spacer()

                        if progress.isCompleted {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.traditional.vermilion)
                                .font(.caption)
                        }
                    }
                }
            }
            .traditionalCard()
        }
        .alert("删除拼图", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deletePuzzle()
            }
        } message: {
            Text("确定要删除这个自制拼图吗？此操作无法撤销。")
        }
    }

    private func deletePuzzle() {
        if let ugcPuzzle = ugcPuzzle {
            try? ugcManager.deleteUGCPuzzle(ugcPuzzle)
        }
    }

    private var difficultyColor: Color {
        switch level.difficulty {
        case .easy:
            return .traditional.indigo
        case .standard:
            return .traditional.ocher
        case .hard:
            return .traditional.vermilion
        }
    }
}

// MARK: - Level Card
struct LevelCard: View {
    let level: PuzzleLevel
    let pageLabel: String?
    let isUnlocked: Bool
    let lockReason: String?
    @ObservedObject private var persistenceManager = PersistenceManager.shared

    private var progress: PuzzleProgress {
        persistenceManager.getGameProgress(forStableId: level.stableId)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .center) {
                    Image(level.previewImageName)
                        .resizable()
                        .scaledToFit() 
                        .frame(width: .infinity, height: 120, alignment: .center) 
                        .cornerRadius(12)
                        .clipped()

                    if let pageLabel {
                        VStack {
                            HStack {
                                Text(pageLabel)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.traditional.ink)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(Color.traditional.paper.opacity(0.92))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.traditional.ocher.opacity(0.35), lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                    
                    if !isUnlocked {
                        Color.traditional.paper.opacity(0.35)
                            .cornerRadius(12)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.traditional.ink.opacity(0.3))
                            .shadow(radius: 3)
                    }
                    // else{
                    //     Image(systemName: difficultyIcon)
                    //         .font(.system(size: 30))
                    //         .foregroundColor(.traditional.indigo)
                    //         .background(Color.white.opacity(0.7))
                    //         .clipShape(Circle())
                    // }
                }
                .frame(height: 120)
                .background(Color.traditional.lightGray)
                .cornerRadius(12)
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.system(.headline, design: .serif))
                        .fontWeight(.medium)
                        .foregroundColor(.traditional.ink)
                        .lineLimit(1)
                    
                    HStack {
                        Text(level.difficulty.rawValue)
                            .font(.qianTuBiFeng(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(difficultyColor.opacity(0.1))
                            .foregroundColor(difficultyColor)
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        if progress.isCompleted {
                            Image(systemName: "seal.fill") // 换成印章图标更中国风
                                .foregroundColor(.traditional.vermilion)
                                .font(.caption)
                        }
                    }

                    if let lockReason, !isUnlocked {
                        Text(lockReason)
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(.traditional.vermilion)
                            .lineLimit(2)
                    }
                }
            }
            .traditionalCard()
            .opacity(isUnlocked ? 1.0 : 0.72)
        }
    }
    
    private var difficultyIcon: String {
        switch level.difficulty {
        case .easy:
            return "star.fill" // 可以考虑自定义图标，例如 "1" 或 "一"
        case .standard:
            return "star.fill"
        case .hard:
            return "star.fill"
        }
    }
    
    private var difficultyColor: Color {
        switch level.difficulty {
        case .easy:
            return .traditional.indigo
        case .standard:
            return .traditional.ocher
        case .hard:
            return .traditional.vermilion
        }
    }
}

#Preview {
    NavigationStack {
        CategoryView(category: PuzzleCategory(
            title: "民居",
            description: "青砖黛瓦、粉墙飞檐的传统民居建筑拼图",
            coverImageName: "category_minju"
        ))
    }
}
