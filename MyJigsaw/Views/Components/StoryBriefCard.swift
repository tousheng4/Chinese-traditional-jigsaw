//
//  StoryBriefCard.swift
//  MyJigsaw
//
//  Created by Codex on 2026/4/25.
//

import SwiftUI

struct StoryBriefCard: View {
    let chapter: StoryChapter
    let narrative: LevelNarrative
    let pageLabel: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("修缮委托")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.traditional.vermilion)

                Spacer()

                HStack(spacing: 8) {
                    capsuleText(chapter.chapterLabel)
                    if let pageLabel {
                        capsuleText(pageLabel)
                    }
                }
            }

            Text(narrative.commissionTitle)
                .font(.qianTuBiFeng(size: 24))
                .foregroundColor(.traditional.ink)

            Text(chapter.summary)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(.traditional.ink.opacity(0.72))
                .lineSpacing(4)

            VStack(spacing: 10) {
                detailRow(title: "修复对象", body: narrative.objectName)
                detailRow(title: "当前残损", body: narrative.damageDescription)
                detailRow(title: "本次目标", body: narrative.repairGoal)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("师父批注")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.traditional.ink.opacity(0.6))
                Text(narrative.masterNote)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(.traditional.ink)
                    .lineSpacing(4)
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(Color.white.opacity(0.92))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.traditional.ocher.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.traditional.ink.opacity(0.06), radius: 10, x: 0, y: 5)
    }

    private func capsuleText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.traditional.ink.opacity(0.75))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.traditional.paper)
            .overlay(
                Capsule()
                    .stroke(Color.traditional.ocher.opacity(0.3), lineWidth: 1)
            )
            .clipShape(Capsule())
    }

    private func detailRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.traditional.ink.opacity(0.58))
            Text(body)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(.traditional.ink.opacity(0.88))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    StoryBriefCard(
        chapter: StoryChapter(
            categoryTitle: "民居",
            chapterLabel: "第一卷",
            chapterTitle: "人间有屋",
            summary: "修卷先从民居开始。若连人如何安身都忘了，再宏伟的建筑也只剩空壳。",
            objective: "",
            toneLine: ""
        ),
        narrative: LevelNarrative(
            levelStableId: "民居_简单",
            commissionTitle: "修复四合院残图",
            objectName: "北京四合院",
            damageDescription: "院门、影壁与正房的关系已被岁月磨糊。",
            repairGoal: "复原院落布局，让家的尺度重新归页。",
            masterNote: "先看门，再看院，再看人如何在屋中安身。",
            completionTitle: "",
            completionBody: "",
            sealText: "首卷启页"
        ),
        pageLabel: "卷内第一页"
    )
    .padding()
    .background(Color.traditional.paper)
}
