//
//  MicroAnnotationCard.swift
//  MyJigsaw
//
//  微注释卡片视图
//

import SwiftUI

struct MicroAnnotationCard: View {
    let annotationPack: MicroAnnotationPack
    let isFirstCompletion: Bool
    @State private var showingDetail = false

    private var primaryNote: MicroNote? {
        annotationPack.primaryNote
    }

    private var secondaryNote: MicroNote? {
        annotationPack.secondaryNote
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Text("微注释")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.traditional.ink.opacity(0.8))

                Spacer()

                // 展开按钮
                Button(action: {
                    showingDetail = true
                }) {
                    HStack(spacing: 4) {
                        Text("了解更多")
                            .font(.system(size: 14))
                            .foregroundColor(.traditional.vermilion)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.traditional.vermilion)
                    }
                }
            }

            // 注释内容
            VStack(alignment: .leading, spacing: 8) {
                if let primaryNote = primaryNote {
                    Text(primaryNote.text)
                        .font(.system(size: 14))
                        .foregroundColor(.traditional.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if isFirstCompletion, let secondaryNote = secondaryNote {
                    Text(secondaryNote.text)
                        .font(.system(size: 14))
                        .foregroundColor(.traditional.ink.opacity(0.8))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.traditional.ocher.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showingDetail) {
            MicroAnnotationDetailView(annotationPack: annotationPack)
        }
    }
}

#Preview {
    let samplePack = MicroAnnotationPack(
        id: "sample_pack",
        artworkId: "sample_artwork",
        microNotes: [
            MicroNote(id: "note1", text: "这是第一条微注释内容，介绍了作品的基本特征。", priority: 0, tone: .beginner, relatedHotspotIds: nil),
            MicroNote(id: "note2", text: "这是第二条微注释，提供了更深入的解读。", priority: 1, tone: .advanced, relatedHotspotIds: nil)
        ],
        detailSections: [
            DetailSection(id: "detail1", title: "作品信息", body: "作品详细信息", references: nil)
        ]
    )

    return MicroAnnotationCard(annotationPack: samplePack, isFirstCompletion: true)
        .padding()
        .background(Color.traditional.paper)
}
