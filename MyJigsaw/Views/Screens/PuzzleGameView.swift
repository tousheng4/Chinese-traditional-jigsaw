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
    @State private var showingCompletion = false
    @State private var showingPauseMenu = false
    @State private var ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var activeDragPieceId: UUID?
    @State private var cachedUGCBoardImage: UIImage?

    // 微注释相关
    private var microAnnotationPack: MicroAnnotationPack? {
        contentManager.getMicroAnnotationPack(for: level)
    }

    private var isFirstCompletion: Bool {
        let progress = PersistenceManager.shared.getGameProgress(forStableId: level.stableId)
        // 如果之前没有完成过，则为首次完成
        return !progress.isCompleted
    }
    
    var body: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height) * 0.8
            ZStack {
                // Background
                Color.traditional.paper.ignoresSafeArea()
                
                if puzzleEngine.gameState.isGameActive {
                    // Game board - 允许碎片移动到任意位置
                    puzzleBoard(boardSize: boardSize, screenSize: geometry.size)
                    
                    // Game UI overlay
                    VStack {
                        // Top bar
                        gameTopBar
                            .padding()
                        
                        Spacer()
                        
                        // Bottom bar
                        gameBottomBar
                            .padding()
                    }
                } else if !puzzleEngine.gameState.isGameCompleted {
                    // Start screen
                    startScreen(boardSize: boardSize)
                }
                
                // Completion screen
                if puzzleEngine.gameState.isGameCompleted {
                    Color.traditional.ink.opacity(0.7)
                        .ignoresSafeArea()

                    completionScreen
                        .onAppear {
                            // 恭喜界面出现时播放成功音效
                            SoundManager.shared.playSucceedSound()
                        }
                }
            }
            // 预热UGC棋盘图缓存：确保开始页也能尽快拿到图（同时提升进入游戏后的流畅度）
            .task(id: boardSize) {
                updateCachedUGCBoardImage(boardSize: boardSize)
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
    private func puzzleBoard(boardSize: CGFloat, screenSize: CGSize) -> some View {
        let gridSize = level.gridSize
        let pieceSize = boardSize / CGFloat(gridSize)
        // 计算棋盘在屏幕中的中心偏移（用于坐标转换）
        let boardOriginX = (screenSize.width - boardSize) / 2
        let boardOriginY = (screenSize.height - boardSize) / 2
        let ugcImage = cachedUGCBoardImage

        return ZStack {
            // Background board - 显式设置 frame 确保布局正确
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.traditional.ocher.opacity(0.1))
                .frame(width: boardSize, height: boardSize)
                .shadow(color: Color.traditional.ink.opacity(0.1), radius: 10)
                .position(x: screenSize.width / 2, y: screenSize.height / 2)

            // 可选：在棋盘底层铺一张"同规则裁切"的整图（用于提示/对齐感知）
            // 注意：不参与点击命中，避免影响拖拽。
            Group {
                if let ugcImage {
                    Image(uiImage: ugcImage)
                        .resizable()
                } else {
                    Image(level.previewImageName)
                        .resizable()
                }
            }
            .scaledToFill()
            .frame(width: boardSize, height: boardSize)
            .clipped()
            .opacity(puzzleEngine.gameState.showHint ? 0.25 : 0.0)
            .allowsHitTesting(false)
            .position(x: screenSize.width / 2, y: screenSize.height / 2)
            
            // Grid lines (optional visual guide)
            if settingsManager.appSettings.showGuideOverlay {
                gridLines(size: boardSize, gridSize: gridSize)
                    .frame(width: boardSize, height: boardSize)
                    .allowsHitTesting(false)
                    .position(x: screenSize.width / 2, y: screenSize.height / 2)
            }
            
            // Puzzle pieces - 使用精确的 frame 和 position 确保手势区域正确
            ForEach(puzzleEngine.gameState.puzzlePieces) { piece in
                PuzzlePieceView(
                    piece: piece,
                    gridSize: gridSize,
                    boardSize: boardSize,
                    imageName: level.previewImageName,
                    sourceImage: ugcImage,
                    isSelected: puzzleEngine.gameState.selectedPieceId == piece.id,
                    showHint: puzzleEngine.gameState.showHint
                )
                // 关键：先设置 frame 限定碎片大小，确保手势检测区域只在碎片的实际大小范围内
                .frame(width: pieceSize, height: pieceSize)
                .contentShape(Rectangle()) // 确保整个碎片区域可响应手势
                .gesture(
                    DragGesture(minimumDistance: 1, coordinateSpace: .named("gameArea"))
                        .onChanged { value in
                            // 记录当前正在拖拽的 piece
                            activeDragPieceId = piece.id
                            if puzzleEngine.gameState.draggingPieceId != piece.id {
                                puzzleEngine.beginDrag(pieceId: piece.id)
                            }
                            puzzleEngine.updateDrag(pieceId: piece.id, translation: value.translation, boardSize: boardSize, gridSize: gridSize)
                        }
                        .onEnded { _ in
                            puzzleEngine.endDrag(pieceId: piece.id, boardSize: boardSize, gridSize: gridSize)
                            if activeDragPieceId == piece.id {
                                activeDragPieceId = nil
                            }
                        }
                )
                .onTapGesture {
                    puzzleEngine.handlePieceTap(piece)
                }
                // 正在拖拽的碎片 zIndex 最高，其次是选中的，锁定的最低
                .zIndex(
                    activeDragPieceId == piece.id ? 100 :
                    (piece.isLocked ? 0 : (puzzleEngine.gameState.selectedPieceId == piece.id ? 2 : 1))
                )
                // 使用 position 进行绝对定位
                // 碎片的 currentPosition 是相对于棋盘左上角的坐标，需要转换到屏幕坐标
                .position(
                    x: boardOriginX + piece.currentPosition.x,
                    y: boardOriginY + piece.currentPosition.y
                )
            }
        }
        // 使用整个屏幕大小作为游戏区域，允许碎片移动到任意位置
        .frame(width: screenSize.width, height: screenSize.height)
        .coordinateSpace(name: "gameArea")
        // UGC图片：按棋盘尺寸缓存降采样图，减少渲染开销
        .onAppear {
            updateCachedUGCBoardImage(boardSize: boardSize)
        }
        .onChange(of: level.id) { _, _ in
            updateCachedUGCBoardImage(boardSize: boardSize)
        }
        .onChange(of: boardSize) { _, _ in
            updateCachedUGCBoardImage(boardSize: boardSize)
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
    private func startScreen(boardSize: CGFloat) -> some View {
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
            Button(action: { startGame(boardSize: boardSize) }) {
                Text("开始游戏")
            }
            .buttonStyle(TraditionalButtonStyle())
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Completion Screen
    private var completionScreen: some View {
        VStack(spacing: 30) {
            // Success icon
            // Image(systemName: "seal.fill")
            //     .font(.system(size: 80))
            //     .foregroundColor(.traditional.vermilion)
            
            // Completion message
            VStack(spacing: 16) {
                Text("恭喜完成！")
                    .font(.qianTuBiFeng(size: 28))
                    .foregroundColor(.white)
                
                Text("您成功完成了这幅拼图")
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

                Button(action: {
                    showingCompletion = false
                    restartGame()
                }) {
                    Text("再玩一次")
                }
                .buttonStyle(TraditionalButtonStyle(isPrimary: false))
                .background(Color.traditional.paper)
                .cornerRadius(8)
                .padding(.horizontal, 40)

                Button(action: {
                    showingCompletion = false
                    quitGame()
                }) {
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
        .onAppear {
            showingCompletion = true
        }
    }
    
    // MARK: - Game Actions
    private func startGame(boardSize: CGFloat) {
        puzzleEngine.startNewGame(level: level, boardSize: boardSize)
    }

    private func autoCompleteGame() {
        puzzleEngine.autoCompleteGame()
    }

    private func resumeGame() {
        // Resume game logic
    }

    private func restartGame() {
        puzzleEngine.endGame()
        // 这里不直接重启，因为需要棋盘尺寸；用户点击"开始游戏"会重新传入 boardSize
    }

    private func quitGame() {
        puzzleEngine.endGame()
        dismiss()
    }

    private func shareCompletion() {
        // 生成分享图片
        DispatchQueue.main.async {
            let shareImage = generateShareImage()
            let activityVC = UIActivityViewController(activityItems: [shareImage], applicationActivities: nil)

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
                    Text("拾珍拼图")
                        .font(.qianTuBiFeng(size: 18))
                        .foregroundColor(.traditional.vermilion)
                    Text("传统文化，指尖留存")
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
