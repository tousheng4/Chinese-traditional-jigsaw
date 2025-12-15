//
//  HomeView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var contentManager = ContentManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingSettings = false
    @State private var showingAchievements = false
    
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
            
            Text("传统文化拼图")
                .traditionalTitle()
            
            Text("在指尖的拆解与复原之间，完成一次与经典图像的温柔相遇")
                .traditionalSubheadline()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 150), spacing: 16)
        ], spacing: 16) {
            ForEach(contentManager.categories) { category in
                NavigationLink(destination: CategoryView(category: category)) {
                    CategoryCard(category: category)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: PuzzleCategory

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            if category.isUGC {
                // UGC分类使用图标
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.traditional.vermilion.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.traditional.vermilion)
                }
            } else {
                // 普通分类使用图片
                Image(category.coverImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .cornerRadius(12)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.system(.headline, design: .serif))
                    .fontWeight(.medium)
                    .foregroundColor(.traditional.ink)
                    .lineLimit(1)

                Text(category.description)
                    .font(.qianTuBiFeng(size: 12))
                    .foregroundColor(.traditional.ink.opacity(0.6))
                    .lineLimit(2)
            }
        }
        .traditionalCard()
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

#Preview {
    HomeView()
}
