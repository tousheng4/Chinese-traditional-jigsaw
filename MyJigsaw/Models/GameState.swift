//
//  GameState.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import Foundation
import SwiftUI

// MARK: - Game State
@Observable
class GameState {
    var currentLevel: PuzzleLevel?
    var puzzlePieces: [PuzzlePiece] = []
    var selectedPieceId: UUID?
    var draggingPieceId: UUID?
    var draggingStartCenter: CGPoint?
    var isGameActive: Bool = false
    var isGameCompleted: Bool = false
    var moveCount: Int = 0
    var startTime: Date?
    var elapsedTime: TimeInterval = 0
    var showHint: Bool = false
    /// 吸附阈值系数（相对于单块边长的比例）。例如 0.30 表示 < 0.30 * pieceSize 即吸附。
    var snapThresholdFactor: CGFloat = 0.30

    // MARK: - Grid Helpers (board pixel space)
    private func gridIndex(for center: CGPoint, cell: CGFloat, gridSize: Int) -> (col: Int, row: Int) {
        let rawCol = (center.x / cell) - 0.5
        let rawRow = (center.y / cell) - 0.5
        let col = min(max(Int(rawCol.rounded()), 0), gridSize - 1)
        let row = min(max(Int(rawRow.rounded()), 0), gridSize - 1)
        return (col, row)
    }

    private func centerForCell(col: Int, row: Int, cell: CGFloat) -> CGPoint {
        CGPoint(x: (CGFloat(col) + 0.5) * cell, y: (CGFloat(row) + 0.5) * cell)
    }

    private func isCellOccupied(col: Int, row: Int, excluding pieceId: UUID, cell: CGFloat, gridSize: Int) -> Bool {
        // 允许极小误差（浮点）
        let epsilon = cell * 0.01
        let targetCenter = centerForCell(col: col, row: row, cell: cell)
        return puzzlePieces.contains(where: { p in
            guard p.id != pieceId else { return false }
            let dx = p.currentPosition.x - targetCenter.x
            let dy = p.currentPosition.y - targetCenter.y
            return sqrt(dx * dx + dy * dy) <= epsilon
        })
    }

    private func nearestEmptyCell(from desired: (col: Int, row: Int), excluding pieceId: UUID, cell: CGFloat, gridSize: Int) -> (col: Int, row: Int) {
        if !isCellOccupied(col: desired.col, row: desired.row, excluding: pieceId, cell: cell, gridSize: gridSize) {
            return desired
        }

        // 以“圈”搜索最近空格（按距离从近到远）
        var best: (col: Int, row: Int)? = nil
        var bestDistSq: Int = .max

        for r in 1..<gridSize {
            for dy in -r...r {
                for dx in -r...r {
                    // 只扫边界（ring），减少遍历
                    if abs(dx) != r && abs(dy) != r { continue }
                    let c = desired.col + dx
                    let rr = desired.row + dy
                    if c < 0 || c >= gridSize || rr < 0 || rr >= gridSize { continue }
                    if isCellOccupied(col: c, row: rr, excluding: pieceId, cell: cell, gridSize: gridSize) { continue }

                    let distSq = dx * dx + dy * dy
                    if distSq < bestDistSq {
                        bestDistSq = distSq
                        best = (c, rr)
                    }
                }
            }
            if let best { return best }
        }

        // 极端情况：全满（理论上不会），就返回原格
        return desired
    }

    private func isInsideBoard(center: CGPoint, boardSize: CGFloat) -> Bool {
        center.x >= 0 && center.x <= boardSize && center.y >= 0 && center.y <= boardSize
    }
    
    // MARK: - Game Control
    func startGame(level: PuzzleLevel, boardSize: CGFloat) {
        currentLevel = level
        isGameActive = true
        isGameCompleted = false
        moveCount = 0
        startTime = Date()
        elapsedTime = 0
        selectedPieceId = nil
        draggingPieceId = nil
        draggingStartCenter = nil
        showHint = false
        
        // Initialize puzzle pieces
        initializePuzzlePieces(for: level, boardSize: boardSize)
    }
    
    func endGame() {
        isGameActive = false
        currentLevel = nil
        puzzlePieces = []
        selectedPieceId = nil
        draggingPieceId = nil
        draggingStartCenter = nil
    }
    
    // MARK: - Puzzle Piece Management
    private func initializePuzzlePieces(for level: PuzzleLevel, boardSize: CGFloat) {
        puzzlePieces = []
        let gridSize = level.gridSize
        let cell = boardSize / CGFloat(gridSize)
        let pieceSize = CGSize(width: 1.0 / CGFloat(gridSize), height: 1.0 / CGFloat(gridSize)) // 仍用于裁切比例
        
        // 生成所有碎片的初始位置（在棋盘内随机分布，但打乱顺序）
        var initialPositions: [CGPoint] = []
        
        // 首先，将所有碎片放在棋盘内的网格位置上，但打乱顺序
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                // 在每个格子内添加一些随机偏移，使碎片看起来更自然
                let randomOffsetX = CGFloat.random(in: -cell * 0.2...cell * 0.2)
                let randomOffsetY = CGFloat.random(in: -cell * 0.2...cell * 0.2)
                let position = CGPoint(
                    x: (CGFloat(col) + 0.5) * cell + randomOffsetX,
                    y: (CGFloat(row) + 0.5) * cell + randomOffsetY
                )
                initialPositions.append(position)
            }
        }
        
        // 打乱位置数组
        initialPositions.shuffle()
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let index = row * gridSize + col
                let imageCropRect = CGRect(
                    x: CGFloat(col) * pieceSize.width,
                    y: CGFloat(row) * pieceSize.height,
                    width: pieceSize.width,
                    height: pieceSize.height
                )
                
                // 目标中心点（棋盘像素坐标）
                let targetPosition = CGPoint(
                    x: (CGFloat(col) + 0.5) * cell,
                    y: (CGFloat(row) + 0.5) * cell
                )
                
                // 使用打乱后的位置作为初始位置
                // 确保碎片不在其目标位置（避免一开始就正确）
                var currentPosition = initialPositions[index]
                
                // 如果碎片恰好在目标位置附近，则交换到其他位置
                let distToTarget = sqrt(pow(currentPosition.x - targetPosition.x, 2) + pow(currentPosition.y - targetPosition.y, 2))
                if distToTarget < cell * 0.3 {
                    // 找一个不在目标位置的位置进行交换
                    for i in 0..<initialPositions.count where i != index {
                        let otherTargetRow = i / gridSize
                        let otherTargetCol = i % gridSize
                        let otherTargetPos = CGPoint(
                            x: (CGFloat(otherTargetCol) + 0.5) * cell,
                            y: (CGFloat(otherTargetRow) + 0.5) * cell
                        )
                        let otherDist = sqrt(pow(initialPositions[i].x - otherTargetPos.x, 2) + pow(initialPositions[i].y - otherTargetPos.y, 2))
                        
                        // 如果另一个位置不在其目标位置，进行交换
                        if otherDist >= cell * 0.3 {
                            let temp = currentPosition
                            currentPosition = initialPositions[i]
                            initialPositions[i] = temp
                            break
                        }
                    }
                }
                
                let piece = PuzzlePiece(
                    index: index,
                    imageCropRect: imageCropRect,
                    targetPosition: targetPosition,
                    currentPosition: currentPosition
                )
                
                puzzlePieces.append(piece)
            }
        }
    }
    
    // MARK: - Game Actions
    func selectPiece(_ piece: PuzzlePiece) {
        // 已锁定的块不允许再选中（避免误触抬层级/手势）
        guard piece.isLocked == false else { return }
        selectedPieceId = piece.id
    }

    func beginDrag(pieceId: UUID) {
        guard let piece = puzzlePieces.first(where: { $0.id == pieceId }), piece.isLocked == false else { return }
        draggingPieceId = pieceId
        draggingStartCenter = piece.currentPosition
        selectedPieceId = pieceId
    }
    
    /// 拖拽过程中：仅更新位置（不做吸附/锁定），避免“边拖边吸附”造成乱跳。
    /// - Parameters:
    ///   - translation: 在棋盘坐标系下的位移（point）
    ///   - boardSize: 棋盘边长（point）
    ///   - gridSize: 网格尺寸
    func updateDrag(pieceId: UUID, translation: CGSize, boardSize: CGFloat, gridSize: Int) {
        guard let index = puzzlePieces.firstIndex(where: { $0.id == pieceId }) else { return }
        guard puzzlePieces[index].isLocked == false else { return }
        guard draggingPieceId == pieceId else { return }
        guard let start = draggingStartCenter else { return }
        
        // 允许碎片自由移动到任意位置，不再限制在棋盘范围内
        let newCenter = CGPoint(
            x: start.x + translation.width,
            y: start.y + translation.height
        )
        puzzlePieces[index].currentPosition = newCenter
    }

    /// 拖拽结束：进行吸附判定，必要时锁定，并计步。
    /// - Returns: 是否发生了吸附锁定
    @discardableResult
    func endDrag(pieceId: UUID, boardSize: CGFloat, gridSize: Int) -> Bool {
        guard let index = puzzlePieces.firstIndex(where: { $0.id == pieceId }) else { return false }
        guard puzzlePieces[index].isLocked == false else { return false }
        guard draggingPieceId == pieceId else { return false }

        let cell = boardSize / CGFloat(gridSize)
        let piece = puzzlePieces[index]

        // 如果碎片被放到棋盘外：不吸附，直接保留当前位置
        if !isInsideBoard(center: piece.currentPosition, boardSize: boardSize) {
            draggingPieceId = nil
            draggingStartCenter = nil
            return false
        }

        // 只有松手在棋盘内才算一步（棋盘外调整位置不计步）
        moveCount += 1

        // 1) 棋盘内：自动吸附到最近网格中心（并避免占位冲突）
        let desiredCell = gridIndex(for: piece.currentPosition, cell: cell, gridSize: gridSize)
        let snappedCell = nearestEmptyCell(from: desiredCell, excluding: pieceId, cell: cell, gridSize: gridSize)
        let snappedCenter = centerForCell(col: snappedCell.col, row: snappedCell.row, cell: cell)
        puzzlePieces[index].currentPosition = snappedCenter

        // 2) 如果吸附后的格子就是目标格，则锁定
        let epsilon = cell * 0.01
        let dxT = snappedCenter.x - piece.targetPosition.x
        let dyT = snappedCenter.y - piece.targetPosition.y
        let distToTarget = sqrt(dxT * dxT + dyT * dyT)
        if distToTarget <= epsilon {
            puzzlePieces[index].currentPosition = piece.targetPosition
            puzzlePieces[index].isLocked = true

            // 播放拼图正确吸附音效
            SoundManager.shared.playJigsawSound()

            checkGameCompletion()
            draggingPieceId = nil
            draggingStartCenter = nil
            return true
        }

        draggingPieceId = nil
        draggingStartCenter = nil
        return false
    }
    
    private func checkGameCompletion() {
        let allLocked = puzzlePieces.allSatisfy { $0.isLocked }
        if allLocked {
            isGameCompleted = true
            isGameActive = false
            if let startTime = startTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }

            // 游戏完成时立即保存进度
            if let level = currentLevel {
                PersistenceManager.shared.saveGameProgress(
                    levelStableId: level.stableId,
                    isCompleted: true,
                    time: elapsedTime,
                    moves: moveCount
                )
            }
        }
    }
    
    func toggleHint() {
        showHint.toggle()
    }

    func autoCompleteGame() {
        // 将所有拼图块移动到正确位置并锁定
        for index in puzzlePieces.indices {
            puzzlePieces[index].currentPosition = puzzlePieces[index].targetPosition
            puzzlePieces[index].isLocked = true
        }

        // 触发游戏完成检查
        checkGameCompletion()
    }

    // MARK: - Timer
    func updateTimer() {
        if isGameActive, let startTime = startTime {
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
}
