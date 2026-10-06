//
//  StoryHeroCard.swift
//  MyJigsaw
//
//

import SwiftUI

struct StoryHeroCard: View {
    let collectionTitle: String
    let summary: String
    let activeChapter: StoryChapter?
    let completedPages: Int
    let totalPages: Int
    let finale: StoryFinale?

    private var progressValue: Double {
        guard totalPages > 0 else { return 0 }
        return Double(completedPages) / Double(totalPages)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(finale == nil ? "主线卷册" : "终章归册")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.traditional.vermilion)

                    Text(finale?.title ?? collectionTitle)
                        .font(.qianTuBiFeng(size: 30))
                        .foregroundColor(.traditional.ink)
                }

                Spacer()

                if let finale {
                    Text(finale.sealText)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundColor(.traditional.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.traditional.paper.opacity(0.8))
                        .overlay(
                            Capsule()
                                .stroke(Color.traditional.ocher.opacity(0.35), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                } else if let activeChapter {
                    Text("\(activeChapter.chapterLabel) · \(activeChapter.chapterTitle)")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundColor(.traditional.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.traditional.paper.opacity(0.8))
                        .overlay(
                            Capsule()
                                .stroke(Color.traditional.ocher.opacity(0.35), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
            }

            Text(finale?.summary ?? summary)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(.traditional.ink.opacity(0.82))
                .lineSpacing(5)

            VStack(alignment: .leading, spacing: 10) {
                ProgressView(value: progressValue)
                    .tint(.traditional.vermilion)
                    .background(Color.traditional.ocher.opacity(0.12))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("已修复")
                            .font(.system(size: 12))
                            .foregroundColor(.traditional.ink.opacity(0.6))
                        Text("\(completedPages)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.traditional.ink)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("待归册")
                            .font(.system(size: 12))
                            .foregroundColor(.traditional.ink.opacity(0.6))
                        Text("\(max(totalPages - completedPages, 0))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.traditional.vermilion)
                    }
                }
            }

            if let finale {
                Text(finale.note)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(.traditional.ink.opacity(0.72))
                    .padding(.top, 2)
            } else if let activeChapter {
                Text(activeChapter.toneLine)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(.traditional.ink.opacity(0.72))
                    .padding(.top, 2)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.94),
                            Color.traditional.paper
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.traditional.ocher.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.traditional.ink.opacity(0.07), radius: 14, x: 0, y: 8)
    }
}

#Preview {
    StoryHeroCard(
        collectionTitle: "《华夏营造志》",
        summary: "修复残卷中的屋舍、桥梁、衙署与宫阙，让华夏建筑的记忆重新归册。",
        activeChapter: StoryChapter(
            categoryTitle: "民居",
            chapterLabel: "第一卷",
            chapterTitle: "人间有屋",
            summary: "",
            objective: "",
            toneLine: "建筑最早安顿的，是人心。"
        ),
        completedPages: 3,
        totalPages: 14,
        finale: nil
    )
    .padding()
    .background(Color.traditional.paper)
}
