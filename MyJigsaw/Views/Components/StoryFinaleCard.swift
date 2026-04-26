//
//  StoryFinaleCard.swift
//  MyJigsaw
//
//  Created by Codex on 2026/4/25.
//

import SwiftUI

struct StoryFinaleCard: View {
    let finale: StoryFinale

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("终章")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.traditional.vermilion)

                    Text(finale.title)
                        .font(.qianTuBiFeng(size: 24))
                        .foregroundColor(.traditional.ink)
                }

                Spacer()

                Text(finale.sealText)
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

            Text(finale.summary)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(.traditional.ink.opacity(0.9))
                .lineSpacing(5)

            Text(finale.note)
                .font(.system(size: 13, design: .serif))
                .foregroundColor(.traditional.ink.opacity(0.72))
                .lineSpacing(4)
        }
        .padding(18)
        .background(Color.white.opacity(0.93))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.traditional.ocher.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    StoryFinaleCard(
        finale: StoryFinale(
            title: "终章归册",
            summary: "《华夏营造志》已修复完成。你修回的不是孤立的屋宇，而是一部关于家园、道路、秩序与中心的文明卷册。",
            note: "建筑被修复的，从来不只是外表，而是后来者重新理解来处的能力。",
            sealText: "全卷终成"
        )
    )
    .padding()
    .background(Color.traditional.paper)
}
