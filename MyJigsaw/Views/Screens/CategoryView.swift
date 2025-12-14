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
    
    private var levels: [PuzzleLevel] {
        contentManager.getLevels(for: category.id)
    }
    
    var body: some View {
        ZStack {
            Color.traditional.paper.ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    headerSection
                    
                    levelsGrid
                }
                .padding()
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.large)
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

// MARK: - Level Card
struct LevelCard: View {
    let level: PuzzleLevel
    @StateObject private var persistenceManager = PersistenceManager.shared
    
    private var progress: PuzzleProgress {
        persistenceManager.getGameProgress(for: level.id)
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
                        .traditionalHeadline()
                        .lineLimit(1)
                    
                    HStack {
                        Text(level.difficulty.rawValue)
                            .font(.caption)
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
