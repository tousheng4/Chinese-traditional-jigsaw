//
//  MicroAnnotationDetailView.swift
//  MyJigsaw
//
//  微注释详情展开页
//

import SwiftUI

struct MicroAnnotationDetailView: View {
    let annotationPack: MicroAnnotationPack
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 所有微注释
                    VStack(alignment: .leading, spacing: 16) {
                        Text("微注释")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.traditional.ink)

                        ForEach(annotationPack.microNotes.sorted { $0.priority < $1.priority }) { note in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(note.text)
                                    .font(.system(size: 16))
                                    .foregroundColor(.traditional.ink)
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)

                                if let tone = note.tone {
                                    Text(tone.rawValue)
                                        .font(.system(size: 12))
                                        .foregroundColor(.traditional.indigo)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.traditional.indigo.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.traditional.ocher.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }

                    // 详情段落
                    VStack(alignment: .leading, spacing: 16) {
                        Text("详细解读")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.traditional.ink)

                        ForEach(annotationPack.detailSections) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(section.title)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.traditional.vermilion)

                                Text(section.body)
                                    .font(.system(size: 15))
                                    .foregroundColor(.traditional.ink.opacity(0.9))
                                    .lineSpacing(8)
                                    .fixedSize(horizontal: false, vertical: true)

                                if let references = section.references, !references.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("参考资料：")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.traditional.ink.opacity(0.7))

                                        ForEach(references, id: \.self) { reference in
                                            Text("• \(reference)")
                                                .font(.system(size: 13))
                                                .foregroundColor(.traditional.ink.opacity(0.6))
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.traditional.ocher.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color.traditional.paper.ignoresSafeArea())
            .navigationTitle("文化解读")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.traditional.vermilion)
                }
            }
        }
    }
}

#Preview {
    let samplePack = MicroAnnotationPack(
        id: "sample_pack",
        artworkId: "sample_artwork",
        microNotes: [
            MicroNote(id: "note1", text: "这是第一条微注释内容，介绍了作品的基本特征和文化内涵。", priority: 0, tone: .beginner, relatedHotspotIds: nil),
            MicroNote(id: "note2", text: "这是第二条微注释，提供了更深入的艺术分析和历史背景。", priority: 1, tone: .advanced, relatedHotspotIds: nil)
        ],
        detailSections: [
            DetailSection(
                id: "detail1",
                title: "作品信息",
                body: "《示例作品》\n年代：明代（约16世纪）\n题材：山水风景\n流派：浙派山水\n\n这是一幅典型的浙派山水画作品，以细腻的笔触和淡雅的墨色著称。",
                references: ["《中国绘画史》", "故宫博物院藏品资料"]
            ),
            DetailSection(
                id: "detail2",
                title: "艺术特色",
                body: "浙派山水讲究笔墨精致，注重写生。画面中山石的皴法和树木的画法都体现了这一派的艺术特点。整体构图采用传统的三段式布局，体现了中国画的章法美学。",
                references: ["中国美术学院资料"]
            )
        ]
    )

    return MicroAnnotationDetailView(annotationPack: samplePack)
}
