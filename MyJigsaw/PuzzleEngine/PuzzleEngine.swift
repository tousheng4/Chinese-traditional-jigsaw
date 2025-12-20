//
//  PuzzleEngine.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - Puzzle Engine
class PuzzleEngine: ObservableObject {
    @Published var gameState = GameState()

    private let persistenceManager = PersistenceManager.shared
    private let settingsManager = SettingsManager.shared
    private let achievementCenter = AchievementCenter.shared
    
    // MARK: - Initialization
    init() {
        // 统一量纲：吸附阈值用“单块边长比例”
        gameState.snapThresholdFactor = settingsManager.appSettings.reduceMotionOverride ? 0.40 : 0.30
    }
    
    // MARK: - Game Management
    func startNewGame(level: PuzzleLevel, boardSize: CGFloat) {
        gameState.startGame(level: level, boardSize: boardSize)
        
        // Play start sound if enabled
        if settingsManager.appSettings.soundEnabled {
            playSound(.gameStart)
        }
    }
    
    func endGame() {
        if gameState.isGameCompleted {
            // Save progress
            if let level = gameState.currentLevel {
                persistenceManager.saveGameProgress(
                    levelStableId: level.stableId,
                    isCompleted: true,
                    time: gameState.elapsedTime,
                    moves: gameState.moveCount
                )

                // 触发成就评估
                achievementCenter.handleLevelCompleted(levelStableId: level.stableId, categoryId: level.categoryId.uuidString)

                // 注意：成功音效现在在恭喜界面出现时播放

                // Trigger haptic feedback if enabled
                if settingsManager.appSettings.hapticsEnabled {
                    triggerHaptic(.success)
                }
            }
        }

        gameState.endGame()
    }
    
    // MARK: - Piece Interaction
    func beginDrag(pieceId: UUID) {
        gameState.beginDrag(pieceId: pieceId)
    }

    func updateDrag(pieceId: UUID, translation: CGSize, boardSize: CGFloat, gridSize: Int) {
        gameState.updateDrag(pieceId: pieceId, translation: translation, boardSize: boardSize, gridSize: gridSize)
    }

    func endDrag(pieceId: UUID, boardSize: CGFloat, gridSize: Int) {
        let snapped = gameState.endDrag(pieceId: pieceId, boardSize: boardSize, gridSize: gridSize)
        if snapped, settingsManager.appSettings.hapticsEnabled {
            triggerHaptic(.light)
        }
    }
    
    func handlePieceTap(_ piece: PuzzlePiece) {
        guard piece.isLocked == false else { return }
        gameState.selectPiece(piece)

        // Provide haptic feedback
        if settingsManager.appSettings.hapticsEnabled {
            triggerHaptic(.selection)
        }
    }

    func autoCompleteGame() {
        gameState.autoCompleteGame()
    }
    
    // MARK: - Audio & Haptics
    private func playSound(_ sound: SoundEffect) {
        // Implementation would go here
        // For now, this is a placeholder
    }
    
    private func triggerHaptic(_ style: HapticStyle) {
        // Implementation would go here
        // For now, this is a placeholder
    }
}

// MARK: - Sound Effects
enum SoundEffect {
    case gameStart
    case pieceSnap
    case gameComplete
    case buttonTap
}

// MARK: - Haptic Styles
enum HapticStyle {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}
