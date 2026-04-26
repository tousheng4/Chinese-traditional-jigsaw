//
//  DialogueSceneView.swift
//  MyJigsaw
//
//  Created by Codex on 2026/4/25.
//
import SwiftUI
import UIKit

struct DialogueSceneView: View {
    let levelTitle: String
    let chapter: StoryChapter?
    let pageLabel: String?
    let lines: [DialogueLine]
    let currentIndex: Int
    let previewImageName: String
    let onAdvance: () -> Void
    let onFinish: () -> Void
    let onSkip: () -> Void
    
    private var currentLine: DialogueLine {
        guard !lines.isEmpty else {
            return DialogueLine(speaker: .spirit, text: "")
        }
        return lines[min(currentIndex, lines.count - 1)]
    }
    
    private var portraitAssetName: String {
        switch currentLine.speaker {
        case .spirit:
            switch chapter?.categoryTitle {
            case "桥梁": return "character_qiaolin"
            case "民居": return "character_yuanling"
            case "官府": return "character_anli"
            case "皇宫": return "character_gongjiang"
            default:    return "character_default"
            }
        case .master: return "character_master"
        case .player: return "character_player"
        }
    }

    private var isLastLine: Bool {
        guard !lines.isEmpty else { return true }
        return currentIndex >= lines.count - 1
    }
    
    private var guideProfile: (name: String, subtitle: String, symbol: String, color: Color) {
        switch chapter?.categoryTitle {
        case "民居":
            return ("院灵·槐安", "守着人间烟火的旧院引路人", "house.fill", .traditional.vermilion)
        case "桥梁":
            return ("桥灵·石衡", "记得水势与桥影的渡口引路人", "bridge", .traditional.indigo)
        case "官府":
            return ("案吏·闻简", "替旧档案守着规制的卷中书吏", "text.book.closed.fill", .traditional.ocher)
        case "皇宫":
            return ("宫匠影·玄梁", "宫阙旧制仍未散去的工匠之影", "building.columns.fill", .traditional.vermilion)
        default:
            return ("卷灵", "卷册引路人", "sparkles", .traditional.vermilion)
        }
    }
    
    var body: some View {
        Group {
            if lines.isEmpty {
                Color.clear
                    .ignoresSafeArea()
                    .onAppear(perform: onFinish)
            } else {
                // 用GeometryReader替代废弃的UIScreen.main，全iOS版本兼容
                GeometryReader { geo in
                    let screenWidth = geo.size.width
                    // 动态判断小屏，无废弃API
                    let isCompact = screenWidth < 390
                    
                    ZStack {
                        // 背景层
                        Image(previewImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .ignoresSafeArea()
                        // 渐变层
                        LinearGradient(
                            colors: [.black.opacity(0.2), .black.opacity(0.4)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea()
                        
                        // 内容层
                        VStack(spacing: 0) {
                            header(isCompact: isCompact)
                                .padding(.horizontal, isCompact ? 16 : 20)
                                .padding(.top, isCompact ? 20 : 24)

                            Spacer()

                            // 半身像 + 对话卡片，负间距使底部略压入卡片
                            VStack(spacing: isCompact ? -36 : -44) {
                                HStack(alignment: .bottom) {
                                    Image(portraitAssetName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: isCompact ? 275 : 350)
                                        .mask(
                                            LinearGradient(
                                                stops: [
                                                    .init(color: .black, location: 0),
                                                    .init(color: .black, location: 0.72),
                                                    .init(color: .clear, location: 1)
                                                ],
                                                startPoint: .top, endPoint: .bottom
                                            )
                                        )
                                        .allowsHitTesting(false)
                                    Spacer()
                                }
                                .padding(.leading, isCompact ? 16 : 20)

                                dialogueCard(isCompact: isCompact)
                                    .padding(.horizontal, isCompact ? 16 : 20)
                            }
                            .padding(.bottom, isCompact ? 32 : 40)
                        }
                    }
                }
            }
        }
    }
    
    // 顶部标题栏
    private func header(isCompact: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                if let chapter {
                    Text("\(chapter.chapterLabel) · \(chapter.chapterTitle)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.traditional.paper.opacity(0.92))
                }
                Text(levelTitle)
                    .font(.qianTuBiFeng(size: isCompact ? 22 : 26))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if let pageLabel {
                    Text(pageLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.traditional.paper)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.25))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                }
            }
            Spacer()
            Button(action: onSkip) {
                Text("跳过剧情")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.traditional.paper)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // 对话卡片（半身像已移到卡片上方，卡片头部只显示文字）
    private func dialogueCard(isCompact: Bool) -> some View {
        let role = currentLine.speaker

        return VStack(alignment: .leading, spacing: 12) {
            // 说话人行
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(speakerName(for: role))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.traditional.ink)
                    Text(speakerSubtitle(for: role))
                        .font(.system(size: 10))
                        .foregroundColor(.traditional.ink.opacity(0.55))
                        .lineLimit(1)
                }
                Spacer()
                Text("\(currentIndex + 1)/\(lines.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.traditional.ink.opacity(0.40))
            }

            Rectangle()
                .fill(Color.traditional.ocher.opacity(0.15))
                .frame(height: 1)

            Text(currentLine.text)
                .font(.system(size: isCompact ? 14 : 15, design: .serif))
                .foregroundColor(.traditional.ink.opacity(0.92))
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(lines.indices, id: \.self) { idx in
                    Capsule()
                        .fill(idx == currentIndex ? Color.traditional.vermilion : Color.traditional.ocher.opacity(0.22))
                        .frame(width: idx == currentIndex ? 18 : 6, height: 5)
                }
                Spacer()
            }

            VStack(spacing: 8) {
                Text(isLastLine ? "点击进入修复" : "点击继续对话")
                    .font(.system(size: 11))
                    .foregroundColor(.traditional.ink.opacity(0.45))
                Button(action: advanceDialogue) {
                    Text(isLastLine ? "进入修复" : "继续对话")
                        .font(.qianTuBiFeng(size: isCompact ? 16 : 17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isCompact ? 10 : 11)
                        .background(Color.traditional.vermilion)
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.traditional.ocher.opacity(0.24), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .simultaneousGesture(TapGesture().onEnded(advanceDialogue))
    }
    
    // 对话推进逻辑
    private func advanceDialogue() {
        guard !lines.isEmpty else {
            onFinish()
            return
        }
        isLastLine ? onFinish() : onAdvance()
    }
    
    // 说话人配置
    private func speakerName(for role: DialogueSpeakerRole) -> String {
        switch role {
        case .spirit: return guideProfile.name
        case .master: return "师父"
        case .player: return "我"
        }
    }
    
    private func speakerSubtitle(for role: DialogueSpeakerRole) -> String {
        switch role {
        case .spirit: return guideProfile.subtitle
        case .master: return "营造修复师"
        case .player: return "修卷者"
        }
    }
    
    private func speakerSymbol(for role: DialogueSpeakerRole) -> String {
        switch role {
        case .spirit: return guideProfile.symbol
        case .master: return "scroll.fill"
        case .player: return "person.fill"
        }
    }
    
    private func speakerColor(for role: DialogueSpeakerRole) -> Color {
        switch role {
        case .spirit: return guideProfile.color
        case .master: return .traditional.ocher
        case .player: return .traditional.indigo
        }
    }
}

// 预览
#Preview {
    DialogueSceneView(
        levelTitle: "赵州桥",
        chapter: StoryChapter(
            categoryTitle: "桥梁",
            chapterLabel: "第二卷",
            chapterTitle: "江河有桥",
            summary: "",
            objective: "",
            toneLine: ""
        ),
        pageLabel: "卷内第三页",
        lines: [
            DialogueLine(speaker: .spirit, text: "第二卷《江河有桥》已展开。"),
            DialogueLine(speaker: .player, text: "我该从哪里下手？"),
            DialogueLine(speaker: .master, text: "给洪水留路，桥才能给行人留路。")
        ],
        currentIndex: 0,
        previewImageName: "zhaozhou_preview",
        onAdvance: {},
        onFinish: {},
        onSkip: {}
    )
}