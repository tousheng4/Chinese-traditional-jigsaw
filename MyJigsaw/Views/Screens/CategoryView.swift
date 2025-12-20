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

    @State private var showDIYCreation = false

    private var levels: [PuzzleLevel] {
        contentManager.getLevels(for: category.id)
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
        VStack(spacing: 12) {
            Image(category.coverImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .cornerRadius(12)
                .clipped()
            
            Text(category.description)
                .traditionalSubheadline()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
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
            if !levels.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("我的拼图")
                        .font(.qianTuBiFeng(size: 22))
                        .foregroundColor(.traditional.ink)

                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 16)
                    ], spacing: 16) {
                        ForEach(levels) { level in
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

    // MARK: - Levels Grid
    private var levelsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 150), spacing: 16)
        ], spacing: 16) {
            ForEach(levels) { level in
                NavigationLink(destination: PuzzleGameView(level: level)) {
                    LevelCard(level: level)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(level.isLocked)
            }
        }
    }

    private var categoryNameIcon: String {
        switch category.title {
        case "传统年画":
            return "paintbrush.fill"
        case "京剧脸谱":
            return "theatermasks.fill"
        case "敦煌壁画":
            return "photo.artframe"
        case "国画":
            return "paintpalette.fill"
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
                    
                    if level.isLocked {
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
                }
            }
            .traditionalCard()
            .opacity(level.isLocked ? 0.7 : 1.0)
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
            title: "传统年画",
            description: "吉祥寓意、节俗叙事的传统年画拼图",
            coverImageName: "category_nianhua"
        ))
    }
}
