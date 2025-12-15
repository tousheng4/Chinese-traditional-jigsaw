//
//  AchievementUnlockToast.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/15.
//

import SwiftUI

struct AchievementUnlockToast: View {
    let achievement: AchievementDefinition

    var body: some View {
        VStack {
            Spacer()
                .frame(height: 60)

            HStack(spacing: 16) {
                // 成就图标
                ZStack {
                    Circle()
                        .fill(Color.traditional.vermilion)
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.traditional.vermilion.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: achievement.iconAssetName)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                // 成就信息
                VStack(alignment: .leading, spacing: 4) {
                    Text("成就解锁！")
                        .font(.qianTuBiFeng(size: 17))
                        .foregroundColor(.traditional.paper)

                    Text(achievement.title)
                        .font(.qianTuBiFeng(size: 20))
                        .foregroundColor(.traditional.paper)

                    Text(achievement.description)
                        .font(.qianTuBiFeng(size: 15))
                        .foregroundColor(.traditional.paper.opacity(0.9))
                        .lineLimit(2)
                }

                Spacer()

                // 关闭按钮
                Image(systemName: "xmark")
                    .foregroundColor(.traditional.paper.opacity(0.7))
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.traditional.ink.opacity(0.95))
                    .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
            )
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        AchievementUnlockToast(achievement: AchievementDefinition(
            id: "test_achievement",
            title: "年画大师",
            description: "完成所有传统年画拼图",
            iconAssetName: "seal.fill",
            criterion: .completeAllLevels(categoryId: "test", difficultyScope: nil, countsOnly: true)
        ))
    }
}
