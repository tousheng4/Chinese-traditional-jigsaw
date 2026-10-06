//
//  StoryReportCard.swift
//  MyJigsaw
//
//

import SwiftUI

struct StoryReportCard: View {
    let chapter: StoryChapter
    let narrative: LevelNarrative
    let pageLabel: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("修复报告")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.traditional.vermilion)

                    Text(narrative.completionTitle)
                        .font(.qianTuBiFeng(size: 22))
                        .foregroundColor(.traditional.ink)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    if let pageLabel {
                        stampText(pageLabel)
                    }
                    stampText(narrative.sealText)
                }
            }

            Text(narrative.completionBody)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(.traditional.ink.opacity(0.88))
                .lineSpacing(5)

            VStack(alignment: .leading, spacing: 6) {
                Text("卷册批注")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.traditional.ink.opacity(0.58))
                Text(chapter.toneLine)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.traditional.ink.opacity(0.74))
                Text(narrative.masterNote)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.traditional.ink.opacity(0.74))
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.92))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.traditional.ocher.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
    }

    private func stampText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.traditional.vermilion)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.traditional.vermilion.opacity(0.08))
            .overlay(
                Capsule()
                    .stroke(Color.traditional.vermilion.opacity(0.35), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

#Preview {
    StoryReportCard(
        chapter: StoryChapter(
            categoryTitle: "桥梁",
            chapterLabel: "第二卷",
            chapterTitle: "江河有桥",
            summary: "",
            objective: "",
            toneLine: "真正高明的桥，不与江河争胜。"
        ),
        narrative: LevelNarrative(
            levelStableId: "桥梁_标准",
            commissionTitle: "",
            objectName: "",
            damageDescription: "",
            repairGoal: "",
            masterNote: "给洪水留路，桥才能给行人留路。",
            completionTitle: "拱券再度跨河",
            completionBody: "当桥影重新落在河面上，赵州桥的智慧也重新站稳。",
            sealText: "桥卷续页"
        ),
        pageLabel: "卷内第二页"
    )
    .padding()
    .background(Color.traditional.paper)
}
