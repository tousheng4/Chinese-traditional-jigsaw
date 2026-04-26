//
//  HomeView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var contentManager = ContentManager.shared
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingSettings = false
    @State private var showingAchievements = false
    private let storyManager = StoryManager.shared

    private var displayCategories: [PuzzleCategory] {
        storyManager.orderedStoryCategories(from: contentManager.categories)
    }

    private var overallProgress: (completed: Int, total: Int) {
        storyManager.overallProgress(
            from: contentManager.categories,
            contentManager: contentManager,
            persistenceManager: persistenceManager
        )
    }

    private var activeChapter: StoryChapter? {
        storyManager.activeChapter(
            from: contentManager.categories,
            contentManager: contentManager,
            persistenceManager: persistenceManager
        )
    }

    private var storyCompleted: Bool {
        storyManager.isStoryCompleted(
            from: contentManager.categories,
            contentManager: contentManager,
            persistenceManager: persistenceManager
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.traditional.paper.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 10) {
                        headerSection
                        
                        categoriesSection
                    }
                    .padding()
                }
            }
            // .navigationTitle("拼图游戏")
            //.navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAchievements = true
                    }) {
                        Image(systemName: "trophy.fill")
                    }

                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAchievements) {
                NavigationStack {
                    AchievementView()
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "puzzlepiece.fill")
                .font(.system(size: 60))
                .foregroundColor(.traditional.vermilion)
            
            Text("拼筑华夏")
                .traditionalTitle()
            
            Text("在指尖之间，重筑华夏建筑之美")
                .traditionalSubheadline()
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            StoryHeroCard(
                collectionTitle: storyManager.collectionTitle,
                summary: storyManager.collectionSummary,
                activeChapter: activeChapter,
                completedPages: overallProgress.completed,
                totalPages: overallProgress.total,
                finale: storyCompleted ? storyManager.finale : nil
            )
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("卷册目录")
                    .font(.qianTuBiFeng(size: 24))
                    .foregroundColor(.traditional.ink)

                Text("选择下一页要修复的建筑残卷")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(.traditional.ink.opacity(0.6))
            }

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150), spacing: 16)
            ], spacing: 16) {
                ForEach(displayCategories) { category in
                    NavigationLink(destination: CategoryView(category: category)) {
                        CategoryCard(
                            category: category,
                            chapter: storyManager.chapter(for: category),
                            progressText: progressText(for: category),
                            isLocked: !isCategoryUnlocked(category),
                            lockText: lockText(for: category)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isCategoryUnlocked(category))
                }
            }
        }
    }

    private func progressText(for category: PuzzleCategory) -> String? {
        guard !category.isUGC else { return nil }
        let progress = storyManager.chapterProgress(
            for: category,
            contentManager: contentManager,
            persistenceManager: persistenceManager
        )
        return "已修复 \(progress.completed)/\(progress.total)"
    }

    private func isCategoryUnlocked(_ category: PuzzleCategory) -> Bool {
        storyManager.isChapterUnlocked(
            category,
            among: contentManager.categories,
            contentManager: contentManager,
            persistenceManager: persistenceManager
        )
    }

    private func lockText(for category: PuzzleCategory) -> String? {
        guard !isCategoryUnlocked(category) else { return nil }
        return storyManager.chapterLockReason(category, among: contentManager.categories)
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: PuzzleCategory
    let chapter: StoryChapter?
    let progressText: String?
    let isLocked: Bool
    let lockText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if category.isUGC {
                // UGC分类使用图标
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.traditional.vermilion.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.traditional.vermilion)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.traditional.ink.opacity(0.35))
                    }
                }
            } else {
                // 普通分类使用图片
                ZStack {
                    Image(category.coverImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .cornerRadius(12)
                        .clipped()

                    if isLocked {
                        Color.traditional.paper.opacity(0.35)
                            .frame(width: 120, height: 120)
                            .cornerRadius(12)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.traditional.ink.opacity(0.42))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let chapter {
                    Text("\(chapter.chapterLabel) · \(chapter.chapterTitle)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.traditional.vermilion)
                }

                Text(category.title)
                    .font(.system(.headline, design: .serif))
                    .fontWeight(.medium)
                    .foregroundColor(.traditional.ink)
                    .lineLimit(1)

                if let statusText = lockText ?? progressText {
                    Text(statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isLocked ? .traditional.vermilion : .traditional.ink.opacity(0.55))
                        .padding(.top, 2)
                }
            }
        }
        .traditionalCard()
        .opacity(isLocked ? 0.72 : 1.0)
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

#Preview {
    HomeView()
}
