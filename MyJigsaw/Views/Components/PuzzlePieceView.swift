//
//  PuzzlePieceView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI
import UIKit

struct PuzzlePieceView: View {
    let piece: PuzzlePiece
    let gridSize: Int
    let boardSize: CGFloat
    let imageName: String
    let sourceImage: UIImage?
    let isSelected: Bool
    let showHint: Bool
    
    var body: some View {
        if let imgName = piece.componentImageName {
            componentView(imageName: imgName)
        } else {
            gridView
        }
    }

    // MARK: - Component Mode View
    private func componentView(imageName: String) -> some View {
        let w = piece.componentDisplaySize.width
        let h = piece.componentDisplaySize.height
        return ZStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: w, height: h)
                .shadow(color: Color.traditional.ink.opacity(piece.isLocked ? 0.0 : 0.35),
                        radius: isSelected ? 10 : 5,
                        x: 0, y: isSelected ? 5 : 2)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)

            if isSelected && !piece.isLocked {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.traditional.vermilion, lineWidth: 2)
                    .frame(width: w, height: h)
            }
        }
        .frame(width: w, height: h)
        .contentShape(Rectangle())
    }

    // MARK: - Grid Mode View
    private var gridView: some View {
        let pieceSize = boardSize / CGFloat(gridSize)

        return ZStack {
            // Main piece
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.traditional.paper)
                .frame(width: pieceSize, height: pieceSize)
                .overlay(
                    imageCropView
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
                )
                .shadow(color: Color.traditional.ink.opacity(0.3), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)

            if showHint && !piece.isLocked {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.traditional.vermilion.opacity(0.3))
                    .frame(width: pieceSize, height: pieceSize)
            }

            if piece.isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.traditional.paper)
                    .padding(4)
                    .background(Color.traditional.ocher)
                    .clipShape(Circle())
                    .offset(x: pieceSize/2 - 10, y: -pieceSize/2 + 10)
            }
        }
        .frame(width: pieceSize, height: pieceSize)
        .contentShape(Rectangle())
    }
    
    // MARK: - Image Crop View
    private var imageCropView: some View {
        let pieceSize = boardSize / CGFloat(gridSize)
        let cropCenterX = (piece.imageCropRect.minX + piece.imageCropRect.width / 2) * boardSize
        let cropCenterY = (piece.imageCropRect.minY + piece.imageCropRect.height / 2) * boardSize
        let offsetX = (boardSize / 2) - cropCenterX
        let offsetY = (boardSize / 2) - cropCenterY

        // 核心思路：所有碎片共享同一张“棋盘尺寸”的图（同一缩放/裁切），
        // 通过平移整图，让当前块应显示的那一格“中心”对齐到碎片视图中心，再 clip 即可。
        return Group {
            if let sourceImage {
                Image(uiImage: sourceImage)
                    .resizable()
            } else {
                Image(imageName)
                    .resizable()
            }
        }
        .scaledToFill()
        .frame(width: boardSize, height: boardSize)
        .clipped()
        .offset(x: offsetX, y: offsetY)
        .frame(width: pieceSize, height: pieceSize)
        .clipped()
    }
    
    // MARK: - Helper Properties
    private var borderColor: Color {
        if piece.isLocked {
            return .traditional.ocher
        } else if isSelected {
            return .traditional.vermilion
        } else {
            return .traditional.ink.opacity(0.2)
        }
    }
    
    private var placeholderColor: Color {
        // Generate a consistent color based on piece index, using traditional colors
        let colors: [Color] = [.traditional.vermilion, .traditional.indigo, .traditional.ocher, .traditional.ink]
        return colors[piece.index % colors.count].opacity(0.8)
    }
}

#Preview {
    VStack(spacing: 20) {
        PuzzlePieceView(
            piece: PuzzlePiece(
                index: 0,
                imageCropRect: CGRect(x: 0, y: 0, width: 0.33, height: 0.33),
                targetPosition: CGPoint(x: 0, y: 0),
                currentPosition: CGPoint(x: 0, y: 0)
            ),
            gridSize: 3,
            boardSize: 300,
            imageName: "sample",
            sourceImage: nil,
            isSelected: false,
            showHint: false
        )
        
        PuzzlePieceView(
            piece: PuzzlePiece(
                index: 1,
                imageCropRect: CGRect(x: 0.33, y: 0, width: 0.33, height: 0.33),
                targetPosition: CGPoint(x: 1, y: 0),
                currentPosition: CGPoint(x: 1, y: 0)
            ),
            gridSize: 3,
            boardSize: 300,
            imageName: "sample",
            sourceImage: nil,
            isSelected: true,
            showHint: false
        )
        
        PuzzlePieceView(
            piece: PuzzlePiece(
                index: 2,
                imageCropRect: CGRect(x: 0.66, y: 0, width: 0.33, height: 0.33),
                targetPosition: CGPoint(x: 2, y: 0),
                currentPosition: CGPoint(x: 2, y: 0),
                isLocked: true
            ),
            gridSize: 3,
            boardSize: 300,
            imageName: "sample",
            sourceImage: nil,
            isSelected: false,
            showHint: true
        )
    }
    .padding()
}
