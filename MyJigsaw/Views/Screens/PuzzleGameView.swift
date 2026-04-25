//
//  PuzzleGameView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI
import Combine
import UIKit

struct PuzzleGameView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.displayScale) private var displayScale
    let level: PuzzleLevel
    @StateObject private var puzzleEngine = PuzzleEngine()
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var contentManager = ContentManager.shared
    @StateObject private var ugcManager = UGCManager.shared
    @StateObject private var persistenceManager = PersistenceManager.shared
    @State private var showingCompletion = false
    @State private var showingPauseMenu = false
    @State private var wasFirstCompletion = false
    @State private var ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var activeDragPieceId: UUID?
    @State private var cachedUGCBoardImage: UIImage?
    // 完成动画状态
    @State private var showBoardReveal = false
    @State private var showConfetti = false
    @State private var showCompletionScreen = false

    // 微注释相关
    private var microAnnotationPack: MicroAnnotationPack? {
        contentManager.getMicroAnnotationPack(for: level)
    }

    private var isFirstCompletion: Bool {
        if showCompletionScreen {
            let progress = PersistenceManager.shared.getGameProgress(forStableId: level.stableId)
            return !progress.isCompleted
        } else if puzzleEngine.gameState.isGameCompleted {
            let progress = PersistenceManager.shared.getGameProgress(forStableId: level.stableId)
            wasFirstCompletion = !progress.isCompleted
            return wasFirstCompletion
        }
        return false
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isComponent = level.puzzleMode == .component
            let boardWidth: CGFloat = isComponent
                ? geometry.size.width * 0.92
                : min(geometry.size.width, geometry.size.height) * 0.8
            let boardHeight: CGFloat = isComponent && level.canvasAspect > 0
                ? boardWidth / level.canvasAspect
                : boardWidth
            let boardSize = boardWidth
            ZStack {
                // Background
                Color.traditional.paper.ignoresSafeArea()
                
                if puzzleEngine.gameState.isGameActive || showBoardReveal {
                    // 游戏进行中或封面揭示动画时显示棋盘
                    puzzleBoard(boardWidth: boardWidth, boardHeight: boardHeight, screenSize: geometry.size)

                    if puzzleEngine.gameState.isGameActive {
                        // Game UI overlay（仅游戏进行时）
                        VStack {
                            gameTopBar
                                .padding()

                            if let def = selectedComponentDef {
                                componentInfoCard(def)
                                    .padding(.horizontal)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            Spacer()

                            gameBottomBar
                                .padding()
                        }
                        .animation(.easeInOut(duration: 0.22), value: selectedComponentDef?.id)
                    }
                } else if !puzzleEngine.gameState.isGameCompleted {
                    startScreen(boardSize: boardSize, screenSize: geometry.size)
                }

                // 彩带
                if showConfetti {
                    ConfettiView(origin: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                }

                // 完成界面（延迟出现）
                if showCompletionScreen {
                    Color.traditional.ink.opacity(0.7)
                        .ignoresSafeArea()
                    completionScreen
                }
            }
            // 预热UGC棋盘图缓存：确保开始页也能尽快拿到图（同时提升进入游戏后的流畅度）
            .task(id: boardSize) {
                updateCachedUGCBoardImage(boardSize: boardSize)
            }
            .onChange(of: puzzleEngine.gameState.isGameCompleted) { _, completed in
                guard completed else { return }
                SoundManager.shared.playSucceedSound()
                withAnimation(.easeInOut(duration: 0.55)) {
                    showBoardReveal = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showConfetti = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
                    showConfetti = false
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showCompletionScreen = true
                    }
                }
            }
        }
        .navigationTitle(level.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // 一键通关按钮
                Button(action: {
                    autoCompleteGame()
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }

                // 暂停按钮
                Button(action: {
                    showingPauseMenu = true
                }) {
                    Image(systemName: "pause.circle.fill")
                        .font(.title2)
                        .foregroundColor(.traditional.ink)
                }
            }
        }
        .onAppear {
            // Don't auto-start the game, let the user tap start
        }
        .onDisappear {
            // no-op: we use Combine timer publisher
        }
        .sheet(isPresented: $showingPauseMenu) {
            PauseMenuView(
                isShowing: $showingPauseMenu,
                onResume: resumeGame,
                onRestart: restartGame,
                onQuit: quitGame
            )
        }
    }
    
    // MARK: - Puzzle Board
    private func puzzleBoard(boardWidth: CGFloat, boardHeight: CGFloat, screenSize: CGSize) -> some View {
        let gridSize = level.gridSize
        let boardOriginX = (screenSize.width - boardWidth) / 2
        let boardOriginY = (screenSize.height - boardHeight) / 2
        let ugcImage = cachedUGCBoardImage
        let isComponent = level.puzzleMode == .component

        return ZStack {
            // 棋盘背景
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.traditional.ocher.opacity(0.1))
                .frame(width: boardWidth, height: boardHeight)
                .shadow(color: Color.traditional.ink.opacity(0.1), radius: 10)
                .position(x: screenSize.width / 2, y: screenSize.height / 2)

            // 提示图（grid 模式：整图半透明叠底；component 模式：各部件叠到目标位置）
            if puzzleEngine.gameState.showHint {
                if isComponent {
                    ForEach(puzzleEngine.gameState.puzzlePieces) { piece in
                        if let imgName = piece.componentImageName {
                            Image(imgName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: piece.componentDisplaySize.width,
                                       height: piece.componentDisplaySize.height)
                                .opacity(0.30)
                                .allowsHitTesting(false)
                                .zIndex(Double(piece.componentZIndex))
                                .position(x: boardOriginX + piece.targetPosition.x,
                                          y: boardOriginY + piece.targetPosition.y)
                        }
                    }
                } else {
                    Group {
                        if let ugcImage {
                            Image(uiImage: ugcImage).resizable()
                        } else {
                            Image(level.previewImageName).resizable()
                        }
                    }
                    .scaledToFill()
                    .frame(width: boardWidth, height: boardHeight)
                    .clipped()
                    .opacity(0.25)
                    .allowsHitTesting(false)
                    .position(x: screenSize.width / 2, y: screenSize.height / 2)
                }
            }

            // 网格线（仅 grid 模式）
            if !isComponent && settingsManager.appSettings.showGuideOverlay {
                gridLines(size: boardWidth, gridSize: gridSize)
                    .frame(width: boardWidth, height: boardWidth)
                    .allowsHitTesting(false)
                    .position(x: screenSize.width / 2, y: screenSize.height / 2)
            }

            // 拼图碎片（完成后隐藏，由封面图取代）
            if !showBoardReveal {
            ForEach(puzzleEngine.gameState.puzzlePieces) { piece in
                let pieceW: CGFloat = isComponent ? piece.componentDisplaySize.width  : boardWidth / CGFloat(gridSize)
                let pieceH: CGFloat = isComponent ? piece.componentDisplaySize.height : boardWidth / CGFloat(gridSize)

                PuzzlePieceView(
                    piece: piece,
                    gridSize: gridSize,
                    boardSize: boardWidth,
                    imageName: level.previewImageName,
                    sourceImage: ugcImage,
                    isSelected: puzzleEngine.gameState.selectedPieceId == piece.id,
                    showHint: puzzleEngine.gameState.showHint
                )
                .frame(width: pieceW, height: pieceH)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1, coordinateSpace: .named("gameArea"))
                        .onChanged { value in
                            activeDragPieceId = piece.id
                            if puzzleEngine.gameState.draggingPieceId != piece.id {
                                puzzleEngine.beginDrag(pieceId: piece.id)
                            }
                            puzzleEngine.updateDrag(pieceId: piece.id, translation: value.translation, boardSize: boardWidth, gridSize: gridSize)
                        }
                        .onEnded { _ in
                            puzzleEngine.endDrag(pieceId: piece.id, boardSize: boardWidth, gridSize: gridSize)
                            if activeDragPieceId == piece.id {
                                activeDragPieceId = nil
                            }
                        }
                )
                .onTapGesture {
                    puzzleEngine.handlePieceTap(piece)
                }
                .zIndex(
                    activeDragPieceId == piece.id ? 1000 :
                    piece.isLocked
                        ? Double(piece.componentZIndex)
                        : Double(500 + (puzzleEngine.gameState.selectedPieceId == piece.id ? 10 : 0))
                )
                .position(
                    x: boardOriginX + piece.currentPosition.x,
                    y: boardOriginY + piece.currentPosition.y
                )
            }
            } // if !showBoardReveal

            // 封面揭示图（完成时替换部件）
            if showBoardReveal {
                Group {
                    if isComponent {
                        Image(level.previewImageName)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(level.previewImageName)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: boardWidth, height: boardHeight)
                .clipped()
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
                .allowsHitTesting(false)
                .position(x: screenSize.width / 2, y: screenSize.height / 2)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
                .zIndex(200)
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .coordinateSpace(name: "gameArea")
        .onAppear {
            updateCachedUGCBoardImage(boardSize: boardWidth)
        }
        .onChange(of: level.id) { _, _ in
            updateCachedUGCBoardImage(boardSize: boardWidth)
        }
        .onChange(of: boardWidth) { _, _ in
            updateCachedUGCBoardImage(boardSize: boardWidth)
        }
    }
    
    // MARK: - Grid Lines
    private func gridLines(size: CGFloat, gridSize: Int) -> some View {
        ZStack {
            // Vertical lines
            ForEach(0..<gridSize + 1, id: \.self) { i in
                Rectangle()
                    .fill(Color.traditional.ocher.opacity(0.3))
                    .frame(width: 1, height: size)
                    .position(x: size * CGFloat(i) / CGFloat(gridSize), y: size / 2)
            }
            
            // Horizontal lines
            ForEach(0..<gridSize + 1, id: \.self) { i in
                Rectangle()
                    .fill(Color.traditional.ocher.opacity(0.3))
                    .frame(width: size, height: 1)
                    .position(x: size / 2, y: size * CGFloat(i) / CGFloat(gridSize))
            }
        }
    }
    
    // MARK: - Hint Overlay
    private func hintOverlay(boardSize: CGFloat) -> some View {
        // 仅作为"提示开启时的轻微色罩"，必须不拦截触控/鼠标事件
        return RoundedRectangle(cornerRadius: 12)
            .fill(Color.traditional.vermilion)
            .frame(width: boardSize, height: boardSize)
            .opacity(0.10)
    }
    
    // MARK: - Game Top Bar
    private var gameTopBar: some View {
        HStack {
            // Move counter
            VStack(alignment: .leading) {
                Text("步数")
                    .font(.system(size: 12))
                    .foregroundColor(.traditional.ink.opacity(0.6))
                Text("\(puzzleEngine.gameState.moveCount)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.traditional.ink)
            }
            
            Spacer()
            
            // Timer (if enabled)
            if settingsManager.appSettings.timerEnabled {
                VStack(alignment: .center) {
                    Text("时间")
                        .font(.system(size: 12))
                        .foregroundColor(.traditional.ink.opacity(0.6))
                    Text(formatTime(puzzleEngine.gameState.elapsedTime))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.traditional.ink)
                        .onReceive(ticker) { _ in
                            guard settingsManager.appSettings.timerEnabled else { return }
                            puzzleEngine.gameState.updateTimer()
                        }
                }
            }
            
            Spacer()
            
            // Hint button
            Button(action: {
                puzzleEngine.gameState.toggleHint()
            }) {
                Image(systemName: puzzleEngine.gameState.showHint ? "eye.slash.fill" : "eye.fill")
                    .font(.title2)
                    .foregroundColor(puzzleEngine.gameState.showHint ? .traditional.vermilion : .traditional.ink)
            }
        }
        .traditionalCard()
    }
    
    // MARK: - Game Bottom Bar
    private var gameBottomBar: some View {
        HStack(spacing: 20) {
            // Shuffle button
            Button(action: {
                // Shuffle pieces
            }) {
                Image(systemName: "shuffle")
                    .font(.title2)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .foregroundColor(.traditional.ink)
                    .overlay(Circle().stroke(Color.traditional.ocher.opacity(0.3), lineWidth: 1))
                    .shadow(color: Color.traditional.ink.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
            
            // Auto-solve button (for debugging)
            Button(action: {
                // Auto-solve puzzle
            }) {
                Image(systemName: "wand.and.stars")
                    .font(.title2)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .foregroundColor(.traditional.ink)
                    .overlay(Circle().stroke(Color.traditional.ocher.opacity(0.3), lineWidth: 1))
                    .shadow(color: Color.traditional.ink.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .padding()
    }
    
    // MARK: - Start Screen
    private func startScreen(boardSize: CGFloat, screenSize: CGSize) -> some View {
        VStack(spacing: 30) {
            // Level preview
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.traditional.lightGray)
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Group {
                        // 开始页优先用缩略图（更快），没有再退回到棋盘图缓存/资源图
                        if let thumb = currentUGCThumbnail() {
                            Image(uiImage: thumb)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                        } else if let ugcImage = cachedUGCBoardImage {
                            Image(uiImage: ugcImage)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                        } else {
                            Image(level.previewImageName)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                        }
                    }
                )
                .padding(.horizontal, 40)
                .shadow(color: Color.traditional.ink.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // Level info
            VStack(spacing: 16) {
                Text(level.title)
                    .traditionalTitle()
                
                Text(level.sourceInfo)
                    .traditionalSubheadline()
                    .multilineTextAlignment(.center)
                
                HStack {
                    Text("难度:")
                        .traditionalSubheadline()
                    
                    Text(level.difficulty.rawValue)
                        .font(.qianTuBiFeng(size: 15))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(difficultyColor.opacity(0.1))
                        .foregroundColor(difficultyColor)
                        .cornerRadius(8)
                }
            }
            
            // Start button
            Button(action: { startGame(boardSize: boardSize, screenSize: screenSize) }) {
                Text("开始游戏")
            }
            .buttonStyle(TraditionalButtonStyle())
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Completion Screen
    private var completionScreen: some View {
        VStack(spacing: 20) {
            // 部件模式：展示完整图片
            if level.puzzleMode == .component {
                Image(level.previewImageName)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.traditional.ocher, lineWidth: 2))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }

            // Completion message
            VStack(spacing: 8) {
                Text("恭喜完成！")
                    .font(.qianTuBiFeng(size: 28))
                    .foregroundColor(.white)

                Text(level.puzzleMode == .component ? "您成功还原了\(level.title)" : "您成功完成了这幅拼图")
                    .font(.qianTuBiFeng(size: 15))
                    .foregroundColor(.traditional.paper.opacity(0.9))
            }
            
            // Stats
            VStack(spacing: 12) {
                HStack {
                    Text("完成步数:")
                        .font(.system(size: 15))
                        .foregroundColor(.traditional.ink.opacity(0.7))
                    Spacer()
                    Text("\(puzzleEngine.gameState.moveCount)")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.traditional.ink)
                }
                
                if settingsManager.appSettings.timerEnabled {
                    HStack {
                        Text("完成时间:")
                            .font(.system(size: 15))
                            .foregroundColor(.traditional.ink.opacity(0.7))
                        Spacer()
                        Text(formatTime(puzzleEngine.gameState.elapsedTime))
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.traditional.ink)
                    }
                }
            }
            .traditionalCard()
            .padding(.horizontal, 40)

            // 微注释卡片
            if let annotationPack = microAnnotationPack {
                MicroAnnotationCard(annotationPack: annotationPack, isFirstCompletion: isFirstCompletion)
                    .padding(.horizontal, 40)
            }

            // Buttons
            VStack(spacing: 16) {
                // 分享按钮
                Button(action: shareCompletion) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("分享完成")
                            .font(.qianTuBiFeng(size: 17))
                    }
                }
                .buttonStyle(TraditionalButtonStyle(isPrimary: false))
                .background(Color.traditional.paper)
                .cornerRadius(8)
                .padding(.horizontal, 40)

                Button(action: { restartGame() }) {
                    Text("再玩一次")
                }
                .buttonStyle(TraditionalButtonStyle(isPrimary: false))
                .background(Color.traditional.paper)
                .cornerRadius(8)
                .padding(.horizontal, 40)

                Button(action: { quitGame() }) {
                    Text("返回")
                }
                .buttonStyle(TraditionalButtonStyle())
                .padding(.horizontal, 40)
            }
        }
        .padding()
        .background(Color.traditional.ink.opacity(0.95)) // 加深背景不透明度
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.traditional.ocher, lineWidth: 2))
        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10) // 添加阴影
        .padding()
    }

    // MARK: - Game Actions
    private func startGame(boardSize: CGFloat, screenSize: CGSize) {
        puzzleEngine.startNewGame(level: level, boardSize: boardSize, screenSize: screenSize)
    }

    private func autoCompleteGame() {
        puzzleEngine.autoCompleteGame()
    }

    private func resumeGame() {
        // Resume game logic
    }

    private func restartGame() {
        puzzleEngine.endGame()
        showBoardReveal = false
        showConfetti = false
        showCompletionScreen = false
    }

    private func quitGame() {
        puzzleEngine.endGame()
        showBoardReveal = false
        showConfetti = false
        showCompletionScreen = false
        dismiss()
    }

    private func shareCompletion() {
        // 生成分享图片
        DispatchQueue.main.async {
            let shareImage = generateShareImage()
            let activityVC = UIActivityViewController(activityItems: [shareImage], applicationActivities: nil)

            // 添加完成回调
            activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                DispatchQueue.main.async {
                    if completed {
                        if activityType?.rawValue == "com.apple.UIKit.activity.SaveToCameraRoll" {
                            // 用户选择了保存到相册，显示成功提示
                            self.showPhotoSaveSuccessAlert()
                        }
                    }
                }
            }

            // 在iPad上设置弹窗位置
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                activityVC.popoverPresentationController?.sourceView = window
                activityVC.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            }

            // 获取当前ViewController并显示分享界面
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }


    private func showPhotoSaveSuccessAlert() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            let alert = UIAlertController(
                title: "保存成功",
                message: "拼图完成图片已保存到相册！",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            rootVC.present(alert, animated: true)
        }
    }

    @MainActor
    private func generateShareImage() -> UIImage {
        let puzzleImage: UIImage?
        if let ugcPuzzle = contentManager.getUGCPuzzle(for: level.id) {
            puzzleImage = ugcManager.getImage(for: ugcPuzzle)
        } else {
            puzzleImage = UIImage(named: level.previewImageName)
        }

        let shareView = ShareResultView(
            level: level,
            moveCount: puzzleEngine.gameState.moveCount,
            elapsedTime: puzzleEngine.gameState.elapsedTime,
            puzzleImage: puzzleImage
        )

        let renderer = ImageRenderer(content: shareView)
        // 设置 renderer 的 scale 为当前显示缩放，保证清晰度
        renderer.scale = displayScale
        
        return renderer.uiImage ?? UIImage()
    }

    private func updateCachedUGCBoardImage(boardSize: CGFloat) {
        guard level.categoryId == UGCManager.ugcCategoryId else {
            cachedUGCBoardImage = nil
            return
        }
        guard let ugcPuzzle = contentManager.getUGCPuzzle(for: level.id) else {
            cachedUGCBoardImage = nil
            return
        }
        // 目标像素：棋盘边长 * 屏幕 scale（上限稍微放大一点避免锯齿）
        let targetMaxPixelSide = boardSize * displayScale * 1.2
        cachedUGCBoardImage = ugcManager.getBoardSizedImage(for: ugcPuzzle, maxPixelSide: targetMaxPixelSide)
    }

    private func currentUGCThumbnail() -> UIImage? {
        guard level.categoryId == UGCManager.ugcCategoryId else { return nil }
        guard let ugcPuzzle = contentManager.getUGCPuzzle(for: level.id) else { return nil }
        return ugcManager.getThumbnail(for: ugcPuzzle) ?? ugcManager.getImage(for: ugcPuzzle)
    }
    
    // MARK: - Component Info
    private var selectedComponentDef: ComponentPieceDefinition? {
        guard level.puzzleMode == .component,
              let selectedId = puzzleEngine.gameState.selectedPieceId,
              let piece = puzzleEngine.gameState.puzzlePieces.first(where: { $0.id == selectedId && !$0.isLocked }),
              let imgName = piece.componentImageName
        else { return nil }
        return level.componentPieces?.first(where: { $0.imageName == imgName })
    }

    private func componentInfoCard(_ def: ComponentPieceDefinition) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(def.name)
                    .font(.qianTuBiFeng(size: 17))
                    .foregroundColor(.traditional.vermilion)
                Text(def.description)
                    .font(.system(size: 13))
                    .foregroundColor(.traditional.ink.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.traditional.paper)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.traditional.ocher.opacity(0.5), lineWidth: 1))
        .shadow(color: Color.traditional.ink.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    // MARK: - Helper Methods
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var difficultyColor: Color {
        switch level.difficulty {
        case .easy:
            return .green
        case .standard:
            return .orange
        case .hard:
            return .red
        }
    }
}

// MARK: - Share Image Design
struct ShareResultView: View {
    let level: PuzzleLevel
    let moveCount: Int
    let elapsedTime: TimeInterval
    let puzzleImage: UIImage?
    
    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Title and Date
            VStack(spacing: 8) {
                Text(level.title)
                    .font(.qianTuBiFeng(size: 36))
                    .foregroundColor(.traditional.ink)
                
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.qianTuBiFeng(size: 14))
                    .foregroundColor(.traditional.ink.opacity(0.6))
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
            
            // Main Content: Puzzle Image
            ZStack {
                // Image Frame
                Rectangle()
                    .fill(Color.traditional.paper)
                    .overlay(
                        Rectangle()
                            .stroke(Color.traditional.ocher, lineWidth: 2)
                            .padding(4)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.traditional.ocher.opacity(0.5), lineWidth: 1)
                            )
                    )
                
                if let image = puzzleImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(15)
                } else {
                    Rectangle()
                        .fill(Color.traditional.lightGray)
                        .overlay(
                            Text("拼图已成")
                                .font(.qianTuBiFeng(size: 24))
                                .foregroundColor(.traditional.ink.opacity(0.3))
                        )
                        .padding(15)
                }
                
                // Seal (朱红印章)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        SealView(text: "大成")
                            .offset(x: -10, y: -10)
                    }
                }
            }
            .frame(width: 300, height: 300)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 40)
            
            // Stats
            HStack(spacing: 40) {
                VStack(alignment: .center, spacing: 4) {
                    Text("步数")
                        .font(.qianTuBiFeng(size: 14))
                        .foregroundColor(.traditional.ink.opacity(0.6))
                    Text("\(moveCount)")
                        .font(.qianTuBiFeng(size: 24))
                        .foregroundColor(.traditional.ink)
                }
                
                VStack(alignment: .center, spacing: 4) {
                    Text("历时")
                        .font(.qianTuBiFeng(size: 14))
                        .foregroundColor(.traditional.ink.opacity(0.6))
                    Text(formattedTime)
                        .font(.qianTuBiFeng(size: 24))
                        .foregroundColor(.traditional.ink)
                }
            }
            .padding(.top, 30)
            
            Spacer()
            
            // Footer: App Info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("拼筑华夏")
                        .font(.qianTuBiFeng(size: 18))
                        .foregroundColor(.traditional.vermilion)
                    Text("在指尖之间，重筑华夏建筑之美")
                        .font(.qianTuBiFeng(size: 10))
                        .foregroundColor(.traditional.ink.opacity(0.4))
                }
                Spacer()
                // Fake QR Code box
                Rectangle()
                    .stroke(Color.traditional.ink.opacity(0.2), lineWidth: 1)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "qrcode")
                            .font(.system(size: 30))
                            .foregroundColor(.traditional.ink.opacity(0.2))
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(width: 400, height: 600) // Fixed size for the share image
        .background(
            ZStack {
                Color.traditional.paper
                // Traditional pattern or texture could go here
                Image(systemName: "circle.grid.3x3.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.02)
                    .foregroundColor(.traditional.ocher)
            }
        )
        .overlay(
            Rectangle()
                .stroke(Color.traditional.ocher, lineWidth: 10)
                .padding(5)
                .overlay(
                    Rectangle()
                        .stroke(Color.traditional.ocher.opacity(0.5), lineWidth: 1)
                        .padding(12)
                )
        )
    }
}

struct SealView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.qianTuBiFeng(size: 14))
            .foregroundColor(.white)
            .padding(4)
            .background(
                Rectangle()
                    .fill(Color.traditional.vermilion)
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                            .padding(1)
                    )
            )
            .rotationEffect(.degrees(-5))
    }
}

#Preview {
    NavigationStack {
        PuzzleGameView(level: PuzzleLevel(
            categoryId: UUID(),
            title: "示例拼图",
            previewImageName: "sample",
            sourceInfo: "这是一个示例拼图",
            gridSize: 3,
            difficulty: .easy,
            isLocked: false
        ))
    }
}
