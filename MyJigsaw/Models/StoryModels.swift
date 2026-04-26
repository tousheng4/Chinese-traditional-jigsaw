//
//  StoryModels.swift
//  MyJigsaw
//
//  Created by Codex on 2026/4/25.
//

import Foundation

struct StoryChapter {
    let categoryTitle: String
    let chapterLabel: String
    let chapterTitle: String
    let summary: String
    let objective: String
    let toneLine: String
}

struct LevelNarrative {
    let levelStableId: String
    let commissionTitle: String
    let objectName: String
    let damageDescription: String
    let repairGoal: String
    let masterNote: String
    let completionTitle: String
    let completionBody: String
    let sealText: String
}

struct StoryFinale {
    let title: String
    let summary: String
    let note: String
    let sealText: String
}

enum DialogueSpeakerRole: Equatable {
    case spirit
    case master
    case player
}

struct DialogueLine: Identifiable {
    let id = UUID()
    let speaker: DialogueSpeakerRole
    let text: String
}
