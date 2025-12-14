//
//  PuzzleGameView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI
import Combine

struct PuzzleGameView: View {
    @Environment(\.dismiss) var dismiss
    let level: PuzzleLevel
    @StateObject private var puzzleEngine = PuzzleEngine()
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingCompletion = false
    @State private var showingPauseMenu = false
    @State private var ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var activeDragPieceId: UUID?
    
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
                }
            }
        }
        .navigationTitle(level.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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

        return ZStack {
            // Background board - 显式设置 frame 确保布局正确
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.traditional.lightGray)
                .frame(width: boardSize, height: boardSize)
                .shadow(color: Color.traditional.ink.opacity(0.1), radius: 10)
                .position(x: screenSize.width / 2, y: screenSize.height / 2)

            // 可选：在棋盘底层铺一张"同规则裁切"的整图（用于提示/对齐感知）
            // 注意：不参与点击命中，避免影响拖拽。
            Image(level.previewImageName)
                .resizable()
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
                    .font(.caption)
                    .foregroundColor(.traditional.ink.opacity(0.6))
                Text("\(puzzleEngine.gameState.moveCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.traditional.ink)
            }
            
            Spacer()
            
            // Timer (if enabled)
            if settingsManager.appSettings.timerEnabled {
                VStack(alignment: .center) {
                    Text("时间")
                        .font(.caption)
                        .foregroundColor(.traditional.ink.opacity(0.6))
                    Text(formatTime(puzzleEngine.gameState.elapsedTime))
                        .font(.title2)
                        .fontWeight(.bold)
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
                    Image(level.previewImageName)
                        .resizable()
                        .scaledToFill()
                        .clipped()
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
                        .font(.subheadline)
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
            Image(systemName: "seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.traditional.vermilion)
            
            // Completion message
            VStack(spacing: 16) {
                Text("恭喜完成！")
                    .traditionalTitle()
                    .foregroundColor(.traditional.paper)
                
                Text("您成功完成了这幅拼图")
                    .traditionalSubheadline()
                    .foregroundColor(.traditional.paper.opacity(0.9))
            }
            
            // Stats
            VStack(spacing: 12) {
                HStack {
                    Text("完成步数:")
                        .font(.subheadline)
                        .foregroundColor(.traditional.ink.opacity(0.7))
                    Spacer()
                    Text("\(puzzleEngine.gameState.moveCount)")
                        .font(.headline)
                        .foregroundColor(.traditional.ink)
                }
                
                if settingsManager.appSettings.timerEnabled {
                    HStack {
                        Text("完成时间:")
                            .font(.subheadline)
                            .foregroundColor(.traditional.ink.opacity(0.7))
                        Spacer()
                        Text(formatTime(puzzleEngine.gameState.elapsedTime))
                            .font(.headline)
                            .foregroundColor(.traditional.ink)
                    }
                }
            }
            .traditionalCard()
            .padding(.horizontal, 40)
            
            // Buttons
            VStack(spacing: 16) {
                Button(action: {
                    showingCompletion = false
                    restartGame()
                }) {
                    Text("再玩一次")
                }
                .buttonStyle(TraditionalButtonStyle(isPrimary: false))
                .background(Color.traditional.paper) // 按钮背景改为白色以在深色覆盖层上可见
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
