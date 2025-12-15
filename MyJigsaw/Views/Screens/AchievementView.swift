//
//  AchievementView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/15.
//

import SwiftUI

struct AchievementView: View {
    @StateObject private var achievementCenter = AchievementCenter.shared

    var body: some View {
        ZStack {
            Color.traditional.paper.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    achievementsList
                }
                .padding()
            }
        }
        .navigationTitle("成就")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // 确保成就状态是最新的
            achievementCenter.evaluateAllAchievements()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.traditional.vermilion)

            Text("传统文化成就")
                .traditionalTitle()

            Text("完成各类拼图，解锁传统文化成就")
                .traditionalSubheadline()
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Achievements List
    private var achievementsList: some View {
        VStack(spacing: 16) {
            ForEach(achievementCenter.achievements) { achievementData in
                AchievementCard(achievementData: achievementData)
            }
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievementData: AchievementViewData

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(achievementData.isCompleted ? Color.traditional.vermilion.opacity(0.1) : Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(achievementData.isCompleted ? Color.traditional.vermilion : Color.traditional.ocher.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(achievementData.isCompleted ? Color.traditional.vermilion : Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)

                    Image(systemName: achievementData.achievement.iconAssetName)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(achievementData.achievement.title)
                            .font(.qianTuBiFeng(size: 17))
                            .foregroundColor(achievementData.isCompleted ? .traditional.ink : .traditional.ink.opacity(0.6))

                        Spacer()

                        if achievementData.isCompleted {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.traditional.vermilion)
                                .font(.title3)
                        }
                    }

                    Text(achievementData.achievement.description)
                        .font(.qianTuBiFeng(size: 15))
                        .foregroundColor(.traditional.ink.opacity(0.7))
                        .lineLimit(2)

                    // Progress bar
                    VStack(spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(achievementData.isCompleted ? Color.traditional.vermilion : Color.traditional.ocher)
                                    .frame(width: geometry.size.width * achievementData.progressPercentage, height: 8)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text("\(achievementData.state.progressCompleted)/\(achievementData.state.progressTotal)")
                                .font(.qianTuBiFeng(size: 12))
                                .foregroundColor(.traditional.ink.opacity(0.6))

                            Spacer()

                            if achievementData.isCompleted, let unlockedAt = achievementData.state.unlockedAt {
                                Text(unlockedAt.formatted(.dateTime.day().month().year()))
                                    .font(.qianTuBiFeng(size: 12))
                                    .foregroundColor(.traditional.vermilion)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .frame(height: 140)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AchievementView()
    }
}
