//
//  StoryManager.swift
//  MyJigsaw
//
//

import Foundation

final class StoryManager {
    static let shared = StoryManager()

    let collectionTitle = "《华夏营造志》"
    let collectionSummary = "修复残卷中的屋舍、桥梁、衙署与宫阙，让华夏建筑的记忆重新归册。"
    let finale = StoryFinale(
        title: "终章归册",
        summary: "《华夏营造志》已修复完成。你修回的不是孤立的屋宇，而是一部关于家园、道路、秩序与中心的文明卷册。",
        note: "建筑被修复的，从来不只是外表，而是后来者重新理解来处的能力。",
        sealText: "全卷终成"
    )

    private let chapterOrder = ["民居", "桥梁", "官府", "皇宫"]

    private let chapters: [String: StoryChapter] = [
        "民居": StoryChapter(
            categoryTitle: "民居",
            chapterLabel: "第一卷",
            chapterTitle: "人间有屋",
            summary: "修卷先从民居开始。若连人如何安身都忘了，再宏伟的建筑也只剩空壳。",
            objective: "修回屋舍与家园，让卷册重新写下人间烟火。",
            toneLine: "建筑最早安顿的，是人心。"
        ),
        "桥梁": StoryChapter(
            categoryTitle: "桥梁",
            chapterLabel: "第二卷",
            chapterTitle: "江河有桥",
            summary: "桥修的不是石木，而是相逢。它让两岸、两城与两种命运还能走向彼此。",
            objective: "校正桥梁结构与路径，让被江河分开的世界重新连接。",
            toneLine: "真正高明的桥，不与江河争胜。"
        ),
        "官府": StoryChapter(
            categoryTitle: "官府",
            chapterLabel: "第三卷",
            chapterTitle: "一城有序",
            summary: "衙署写下的从来不只是威严，还有一个时代如何理解秩序、公道与责任。",
            objective: "修回府署与贡院的规制，让卷册重新显出制度的重量。",
            toneLine: "门楼与廊庑，会替时代说出它的规矩。"
        ),
        "皇宫": StoryChapter(
            categoryTitle: "皇宫",
            chapterLabel: "第四卷",
            chapterTitle: "天下有极",
            summary: "皇宫最容易让人只看见辉煌，可真正支撑辉煌的，是礼制、工艺与权力中心。",
            objective: "复原宫阙与构件秩序，让卷册写下王朝如何安放中心。",
            toneLine: "修复宫阙，不是把辉煌擦亮，而是把秩序看清。"
        )
    ]

    private let chapterLevelOrder: [String: [String]] = [
        "民居": ["民居_简单", "民居_标准", "民居_困难"],
        "桥梁": ["桥梁_简单", "桥梁_标准", "桥梁_困难", "component_zhaozhou_bridge"],
        "官府": ["官府_简单", "官府_标准", "官府_困难"],
        "皇宫": ["皇宫_简单", "皇宫_标准", "皇宫_困难", "component_gugong_palace"]
    ]

    private let narratives: [String: LevelNarrative] = [
        "民居_简单": LevelNarrative(
            levelStableId: "民居_简单",
            commissionTitle: "修复四合院残图",
            objectName: "北京四合院",
            damageDescription: "院门、影壁与正房的关系已被岁月磨糊，卷中家的秩序开始失真。",
            repairGoal: "复原院落布局，让长幼有序、内外有别的生活尺度重新归页。",
            masterNote: "先看门，再看院，再看人如何在屋中安身。",
            completionTitle: "屋舍归位",
            completionBody: "当影壁与正房重新对上中轴，卷中终于有了家的分寸。民居不是单纯的住所，它把一家人的礼序与体面一并收进院落。",
            sealText: "首卷启页"
        ),
        "民居_标准": LevelNarrative(
            levelStableId: "民居_标准",
            commissionTitle: "修复宏村水系图",
            objectName: "安徽宏村",
            damageDescription: "村落与水圳的脉络断裂，白墙黛瓦之间的山水关系正在散失。",
            repairGoal: "重连街巷、水系与院落，让徽派聚落的呼吸重新流动。",
            masterNote: "有些房子不是立在地上，而是立在山水的规矩里。",
            completionTitle: "村落重见呼吸",
            completionBody: "当水脉与屋脊重新咬合，宏村不再只是好看的风景，而是一套人与自然彼此成全的生活方法。",
            sealText: "烟火续页"
        ),
        "民居_困难": LevelNarrative(
            levelStableId: "民居_困难",
            commissionTitle: "修复土楼防御图",
            objectName: "福建土楼",
            damageDescription: "厚墙、门楼与中央院落的层级散乱，这座为族群而建的堡垒只剩下破碎轮廓。",
            repairGoal: "复原聚族而居的完整结构，让漂泊者重新在卷中围起家园。",
            masterNote: "最有力量的墙，不是把人隔开，而是把人守在一起。",
            completionTitle: "家园合围成形",
            completionBody: "当厚墙与内院再次闭合，土楼重新显出守护众人的力量。你修回的不是单一建筑，而是一整个家族的安身之所。",
            sealText: "首卷归档"
        ),
        "桥梁_简单": LevelNarrative(
            levelStableId: "桥梁_简单",
            commissionTitle: "修复洛阳桥海口图",
            objectName: "洛阳桥",
            damageDescription: "桥梁、潮汐与桥基的关系已经模糊，海口之上的通路正在从卷中退去。",
            repairGoal: "拼合跨海石梁与桥基线索，让渡海之路重新清晰。",
            masterNote: "桥梁能留下来，是因为有人先替后来者把路铺好。",
            completionTitle: "海口旧路重现",
            completionBody: "当桥基重新稳住海口，卷中那条通向远方的路又一次出现。桥的意义，从来不只在彼岸，更在有人愿意先把相逢修好。",
            sealText: "桥卷开页"
        ),
        "桥梁_标准": LevelNarrative(
            levelStableId: "桥梁_标准",
            commissionTitle: "修复赵州桥桥影图",
            objectName: "赵州桥",
            damageDescription: "主拱与敞肩的关系被冲散，千年石桥只剩下一道几近失传的结构记忆。",
            repairGoal: "重建桥身轮廓，找回这座古桥跨越洪水与岁月的答案。",
            masterNote: "给洪水留路，桥才能给行人留路。",
            completionTitle: "拱券再度跨河",
            completionBody: "当桥影重新落在河面上，赵州桥的智慧也重新站稳。你修回的不是一座古桥的样貌，而是工匠如何与山河相处的办法。",
            sealText: "桥卷续页"
        ),
        "桥梁_困难": LevelNarrative(
            levelStableId: "桥梁_困难",
            commissionTitle: "修复卢沟桥桥狮图",
            objectName: "卢沟桥",
            damageDescription: "桥孔、栏板与石狮的记忆残缺交错，这页卷轴压着比桥身更沉重的年代。",
            repairGoal: "拼合桥体与历史印记，让这座古桥继续替后来者记住来路。",
            masterNote: "有些桥跨过河流，有些桥跨过时代。",
            completionTitle: "旧桥仍记来处",
            completionBody: "当桥孔与栏板重新合上，卢沟桥不再只是石桥本身，它也继续托住了一段必须被记住的历史。",
            sealText: "桥卷压轴"
        ),
        "component_zhaozhou_bridge": LevelNarrative(
            levelStableId: "component_zhaozhou_bridge",
            commissionTitle: "校正赵州桥构件图",
            objectName: "赵州桥结构分图",
            damageDescription: "桥台、主拱与小拱的受力关系已经散乱，这页关键构件图几乎无法辨认。",
            repairGoal: "逐一归位关键构件，复原赵州桥千年不倒的结构逻辑。",
            masterNote: "修到这一步，你要看懂的不只是桥面，而是桥为什么还能在这里。",
            completionTitle: "千年结构重合",
            completionBody: "当桥台、主拱与桥面重新扣合，赵州桥的秘密终于不再只是传说。这一页修复完成，整卷桥梁篇也终于真正站稳。",
            sealText: "桥卷定稿"
        ),
        "官府_简单": LevelNarrative(
            levelStableId: "官府_简单",
            commissionTitle: "修复府署中轴图",
            objectName: "淮安府署",
            damageDescription: "照壁、仪门与大堂的次序被侵蚀，府署中轴失去应有的庄重与秩序。",
            repairGoal: "复原前堂后寝的格局，让一城政务重新回到规制之中。",
            masterNote: "看懂一座衙署，也就看懂了一座城怎样安排公与私。",
            completionTitle: "府署重立中轴",
            completionBody: "当中轴线重新笔直，卷中那套关于秩序的语言也重新清楚起来。衙署的威严不在高墙，而在它如何让规矩被看见。",
            sealText: "署卷启页"
        ),
        "官府_标准": LevelNarrative(
            levelStableId: "官府_标准",
            commissionTitle: "修复贡院考棚图",
            objectName: "阆中贡院",
            damageDescription: "号舍与堂楼之间的考试秩序已经散碎，卷中只剩一片沉默的格子。",
            repairGoal: "重建贡院结构，让无数人曾经寄托前途的空间重新成形。",
            masterNote: "有时候最安静的建筑，承受的是最多人的一生。",
            completionTitle: "考棚再成阵列",
            completionBody: "当号舍重新整齐排开，贡院的沉重便又回来了。你修回的不是冷冰冰的格局，而是一代代人曾经押上命运的地方。",
            sealText: "署卷续页"
        ),
        "官府_困难": LevelNarrative(
            levelStableId: "官府_困难",
            commissionTitle: "修复南阳府衙戒石图",
            objectName: "南阳府衙",
            damageDescription: "大堂前后的空间伦理破损严重，衙门只剩形式，公道的意味却在褪色。",
            repairGoal: "复原府衙主空间，让这页卷册重新说清权力与责任的距离。",
            masterNote: "若失了公道，再整齐的屋脊也只是空壳。",
            completionTitle: "规制背后的重量",
            completionBody: "当堂庑与仪门重新严整地站好，府衙真正被修回来的，是它对公正的提醒。至此，卷中的秩序不再只是外形。",
            sealText: "署卷归档"
        ),
        "皇宫_简单": LevelNarrative(
            levelStableId: "皇宫_简单",
            commissionTitle: "修复角楼瞭望图",
            objectName: "故宫角楼",
            damageDescription: "层檐与脊线的关系断裂，这座城角上的目光正在从卷中熄灭。",
            repairGoal: "复原角楼复杂屋顶，让宫城四角重新显出守望与工艺。",
            masterNote: "越复杂的屋顶，越藏不住工匠的心气。",
            completionTitle: "宫城四角再明",
            completionBody: "当层叠檐角重新扣好，角楼不只显出华丽，也显出一座都城如何把警戒与美感同时安放在城墙之上。",
            sealText: "宫卷启页"
        ),
        "皇宫_标准": LevelNarrative(
            levelStableId: "皇宫_标准",
            commissionTitle: "修复午门礼制图",
            objectName: "故宫午门",
            damageDescription: "门阙与楼体的尊卑关系开始模糊，卷中关于进入与止步的礼制正在失焦。",
            repairGoal: "重建午门布局，让王朝中心的尺度与威仪重新可读。",
            masterNote: "门不只是给人通过的，它也规定了谁该止步。",
            completionTitle: "礼制重回门阙",
            completionBody: "当五门与城楼重新归位，午门又一次说明了王朝如何安排距离、身份与目光。宫城的中心感，终于回来了。",
            sealText: "宫卷续页"
        ),
        "皇宫_困难": LevelNarrative(
            levelStableId: "皇宫_困难",
            commissionTitle: "修复盛京皇宫图",
            objectName: "沈阳故宫",
            damageDescription: "殿宇与亭序的格局杂糅失散，这页卷轴正在失去王朝初成时的力量。",
            repairGoal: "拼回多元风格并置的宫城布局，让清初权力结构重新显形。",
            masterNote: "王朝尚未定型时，建筑会最诚实地说出它的来历。",
            completionTitle: "宫城显出源流",
            completionBody: "当大政殿与十王亭重新站定，盛京皇宫重新把一个王朝成形前的气息写回了卷中。",
            sealText: "宫卷压轴"
        ),
        "component_gugong_palace": LevelNarrative(
            levelStableId: "component_gugong_palace",
            commissionTitle: "校正故宫构件图",
            objectName: "故宫大殿结构分图",
            damageDescription: "屋顶、脊兽、门窗与台基层层错位，这一页决定整卷宫阙篇能否真正站住。",
            repairGoal: "逐一复位关键构件，让支撑辉煌的礼制与工艺重新被看见。",
            masterNote: "到最后，修的不再只是表面，而是辉煌背后那套严密的秩序。",
            completionTitle: "宫阙骨架复明",
            completionBody: "当屋顶、梁架、门窗与台基重新扣合，故宫不再只是宏伟图景，而是把礼制、工艺与权力中心一并写回了卷册。",
            sealText: "宫卷定稿"
        )
    ]

    private init() {}

    func chapter(for category: PuzzleCategory) -> StoryChapter? {
        chapters[category.title]
    }

    func chapter(for level: PuzzleLevel, contentManager: ContentManager = .shared) -> StoryChapter? {
        guard let category = contentManager.getCategory(for: level.categoryId) else { return nil }
        return chapter(for: category)
    }

    func narrative(for level: PuzzleLevel) -> LevelNarrative? {
        narratives[level.stableId]
    }

    func introDialogue(for level: PuzzleLevel, contentManager: ContentManager = .shared) -> [DialogueLine] {
        guard let chapter = chapter(for: level, contentManager: contentManager),
              let narrative = narrative(for: level) else {
            return []
        }

        return [
            DialogueLine(
                speaker: .spirit,
                text: "\(chapter.chapterLabel)《\(chapter.chapterTitle)》已展开。眼前这一页残卷，记的是\(narrative.objectName)。"
            ),
            DialogueLine(
                speaker: .player,
                text: "卷上的痕迹已经被岁月搅乱了，我该先从哪里下手？"
            ),
            DialogueLine(
                speaker: .master,
                text: narrative.masterNote
            ),
            DialogueLine(
                speaker: .spirit,
                text: "先记清这次的残损：\(narrative.damageDescription)"
            ),
            DialogueLine(
                speaker: .master,
                text: "你的目标只有一个，\(narrative.repairGoal)"
            ),
            DialogueLine(
                speaker: .player,
                text: "明白。这一页，我会亲手把它修回卷册。"
            )
        ]
    }

    func orderedStoryCategories(from categories: [PuzzleCategory]) -> [PuzzleCategory] {
        categories.sorted { lhs, rhs in
            let lhsIndex = chapterOrder.firstIndex(of: lhs.title) ?? Int.max
            let rhsIndex = chapterOrder.firstIndex(of: rhs.title) ?? Int.max

            if lhsIndex != rhsIndex {
                return lhsIndex < rhsIndex
            }

            if lhs.isUGC != rhs.isUGC {
                return rhs.isUGC == true
            }

            if lhs.sortOrder != rhs.sortOrder {
                return lhs.sortOrder < rhs.sortOrder
            }

            return lhs.title < rhs.title
        }
    }

    func orderedLevels(for category: PuzzleCategory, from contentManager: ContentManager = .shared) -> [PuzzleLevel] {
        let levels = contentManager.getLevels(for: category.id)
        let desiredOrder = chapterLevelOrder[category.title] ?? []

        let mappedLevels = desiredOrder.compactMap { stableId in
            levels.first(where: { $0.stableId == stableId })
        }

        let remainingLevels = levels
            .filter { level in !desiredOrder.contains(level.stableId) }
            .sorted(by: fallbackLevelSort)

        return mappedLevels + remainingLevels
    }

    func isChapterUnlocked(
        _ category: PuzzleCategory,
        among categories: [PuzzleCategory],
        contentManager: ContentManager = .shared,
        persistenceManager: PersistenceManager = .shared
    ) -> Bool {
        guard !category.isUGC else { return true }

        let storyCategories = orderedStoryCategories(from: categories).filter { !$0.isUGC }
        guard let index = storyCategories.firstIndex(where: { $0.id == category.id }) else { return true }
        guard index > 0 else { return true }

        let previousCategory = storyCategories[index - 1]
        let previousProgress = chapterProgress(
            for: previousCategory,
            contentManager: contentManager,
            persistenceManager: persistenceManager
        )
        return previousProgress.total > 0 && previousProgress.completed >= previousProgress.total
    }

    func chapterLockReason(_ category: PuzzleCategory, among categories: [PuzzleCategory]) -> String? {
        guard !category.isUGC else { return nil }

        let storyCategories = orderedStoryCategories(from: categories).filter { !$0.isUGC }
        guard let index = storyCategories.firstIndex(where: { $0.id == category.id }), index > 0 else {
            return nil
        }

        let previousCategory = storyCategories[index - 1]
        guard let previousChapter = chapter(for: previousCategory) else {
            return "完成上一卷后开启"
        }
        return "完成\(previousChapter.chapterLabel)后开启"
    }

    func pageLabel(for level: PuzzleLevel, in category: PuzzleCategory, from contentManager: ContentManager = .shared) -> String? {
        let orderedLevels = orderedLevels(for: category, from: contentManager)
        guard let index = orderedLevels.firstIndex(where: { $0.stableId == level.stableId }) else { return nil }
        return "卷内第\(chineseNumber(for: index + 1))页"
    }

    func isLevelUnlocked(
        _ level: PuzzleLevel,
        in category: PuzzleCategory,
        among categories: [PuzzleCategory],
        contentManager: ContentManager = .shared,
        persistenceManager: PersistenceManager = .shared
    ) -> Bool {
        guard !category.isUGC else { return true }
        guard isChapterUnlocked(category, among: categories, contentManager: contentManager, persistenceManager: persistenceManager) else {
            return false
        }

        let orderedLevels = orderedLevels(for: category, from: contentManager)
        guard let index = orderedLevels.firstIndex(where: { $0.stableId == level.stableId }) else { return true }
        guard index > 0 else { return true }

        let previousLevel = orderedLevels[index - 1]
        return persistenceManager.getGameProgress(forStableId: previousLevel.stableId).isCompleted
    }

    func levelLockReason(
        _ level: PuzzleLevel,
        in category: PuzzleCategory,
        among categories: [PuzzleCategory],
        contentManager: ContentManager = .shared,
        persistenceManager: PersistenceManager = .shared
    ) -> String? {
        guard !category.isUGC else { return nil }

        guard isChapterUnlocked(category, among: categories, contentManager: contentManager, persistenceManager: persistenceManager) else {
            return chapterLockReason(category, among: categories)
        }

        let orderedLevels = orderedLevels(for: category, from: contentManager)
        guard let index = orderedLevels.firstIndex(where: { $0.stableId == level.stableId }), index > 0 else {
            return nil
        }

        let previousLevel = orderedLevels[index - 1]
        if persistenceManager.getGameProgress(forStableId: previousLevel.stableId).isCompleted {
            return nil
        }
        return "完成上一页后解锁"
    }

    func chapterProgress(
        for category: PuzzleCategory,
        contentManager: ContentManager = .shared,
        persistenceManager: PersistenceManager = .shared
    ) -> (completed: Int, total: Int) {
        guard !category.isUGC else { return (0, 0) }

        let levels = orderedLevels(for: category, from: contentManager)
        let completed = levels.reduce(into: 0) { partialResult, level in
            if persistenceManager.getGameProgress(forStableId: level.stableId).isCompleted {
                partialResult += 1
            }
        }
        return (completed, levels.count)
    }

    func overallProgress(
        from categories: [PuzzleCategory],
        contentManager: ContentManager = .shared,
        persistenceManager: PersistenceManager = .shared
    ) -> (completed: Int, total: Int) {
        let storyCategories = orderedStoryCategories(from: categories).filter { !$0.isUGC }
        let progress = storyCategories.map {
            chapterProgress(for: $0, contentManager: contentManager, persistenceManager: persistenceManager)
        }

        let completed = progress.reduce(0) { $0 + $1.completed }
        let total = progress.reduce(0) { $0 + $1.total }
        return (completed, total)
    }

    func isStoryCompleted(
        from categories: [PuzzleCategory],
        contentManager: ContentManager = .shared,
        persistenceManager: PersistenceManager = .shared
    ) -> Bool {
        let progress = overallProgress(
            from: categories,
            contentManager: contentManager,
            persistenceManager: persistenceManager
        )
        return progress.total > 0 && progress.completed >= progress.total
    }

    func activeChapter(
        from categories: [PuzzleCategory],
        contentManager: ContentManager = .shared,
        persistenceManager: PersistenceManager = .shared
    ) -> StoryChapter? {
        let storyCategories = orderedStoryCategories(from: categories).filter { !$0.isUGC }

        for category in storyCategories {
            let progress = chapterProgress(for: category, contentManager: contentManager, persistenceManager: persistenceManager)
            if progress.completed < progress.total {
                return chapter(for: category)
            }
        }

        return storyCategories.last.flatMap { chapter(for: $0) }
    }

    private func fallbackLevelSort(lhs: PuzzleLevel, rhs: PuzzleLevel) -> Bool {
        if lhs.puzzleMode != rhs.puzzleMode {
            return lhs.puzzleMode == .grid
        }

        if difficultyRank(lhs.difficulty) != difficultyRank(rhs.difficulty) {
            return difficultyRank(lhs.difficulty) < difficultyRank(rhs.difficulty)
        }

        return lhs.title < rhs.title
    }

    private func difficultyRank(_ difficulty: PuzzleDifficulty) -> Int {
        switch difficulty {
        case .easy: return 0
        case .standard: return 1
        case .hard: return 2
        }
    }

    private func chineseNumber(for value: Int) -> String {
        let numerals = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        if value >= 0 && value < numerals.count {
            return numerals[value]
        }
        return "\(value)"
    }
}
