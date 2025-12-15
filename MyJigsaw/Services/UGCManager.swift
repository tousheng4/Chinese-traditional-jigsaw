//
//  UGCManager.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/15.
//

import Foundation
import SwiftUI
import PhotosUI
import UIKit
import Combine

@MainActor
class UGCManager: ObservableObject {
    static let shared = UGCManager()
    static let ugcCategoryId: UUID = {
        // 使用一个固定的UUID来标识UGC分类
        return UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!
    }()

    // 存储路径
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let ugcDirectory: URL

    @Published var ugcPuzzles: [UGCPuzzle] = []
    
    // 图片缓存（避免UGC拼图渲染时频繁读盘/解码导致卡顿）
    private let imageCache = NSCache<NSString, UIImage>()

    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        ugcDirectory = documentsDirectory.appendingPathComponent("UGC", isDirectory: true)

        // 确保UGC目录存在
        try? fileManager.createDirectory(at: ugcDirectory, withIntermediateDirectories: true)

        loadUGCPuzzles()
    }

    // MARK: - UGC Puzzle Management

    func createUGCPuzzle(title: String, image: UIImage, config: PuzzleConfig, style: UGCStyleConfig? = nil) async throws -> UGCPuzzle {
        let finalStyle = style ?? UGCStyleConfig(paperTexture: .plain, borderStyle: .none, showSeal: false, sealText: "")
        // 预处理图片
        let processedImage = await preprocessImage(image)
        let thumbnail = await createThumbnail(from: processedImage)

        // 生成文件名
        let puzzleId = UUID()
        let imageFileName = "ugc_\(puzzleId.uuidString)_main.jpg"
        let thumbnailFileName = "ugc_\(puzzleId.uuidString)_thumb.jpg"

        // 保存图片
        let imagePath = ugcDirectory.appendingPathComponent(imageFileName)
        let thumbnailPath = ugcDirectory.appendingPathComponent(thumbnailFileName)

        try saveImage(processedImage, to: imagePath)
        try saveImage(thumbnail, to: thumbnailPath)

        // 创建UGC拼图对象
        let ugcPuzzle = UGCPuzzle(
            id: puzzleId,
            title: title,
            imageAssetPath: imageFileName,
            thumbnailPath: thumbnailFileName,
            config: config,
            style: finalStyle
        )

        // 保存到列表
        ugcPuzzles.append(ugcPuzzle)
        saveUGCPuzzles()

        return ugcPuzzle
    }

    func deleteUGCPuzzle(_ puzzle: UGCPuzzle) throws {
        // 删除文件
        let imagePath = ugcDirectory.appendingPathComponent(puzzle.imageAssetPath)
        let thumbnailPath = ugcDirectory.appendingPathComponent(puzzle.thumbnailPath)

        try? fileManager.removeItem(at: imagePath)
        try? fileManager.removeItem(at: thumbnailPath)

        // 从列表中移除
        ugcPuzzles.removeAll { $0.id == puzzle.id }
        saveUGCPuzzles()

        // 删除进度记录
        deleteProgress(for: puzzle.id)
    }

    func updateUGCPuzzleTitle(_ puzzle: UGCPuzzle, newTitle: String) {
        if let index = ugcPuzzles.firstIndex(where: { $0.id == puzzle.id }) {
            ugcPuzzles[index].title = newTitle
            ugcPuzzles[index].updatedAt = Date()
            saveUGCPuzzles()
        }
    }

    // MARK: - Image Processing

    private func preprocessImage(_ image: UIImage) async -> UIImage {
        // 按目标最大边长缩放，避免内存问题
        let maxDimension: CGFloat = 2048
        let size = image.size

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        if ratio >= 1 {
            return image
        }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        return await resizeImage(image, to: newSize)
    }

    private func createThumbnail(from image: UIImage) async -> UIImage {
        let thumbnailSize = CGSize(width: 512, height: 512)
        return await resizeImage(image, to: thumbnailSize, maintainAspectRatio: true)
    }

    private func resizeImage(_ image: UIImage, to size: CGSize, maintainAspectRatio: Bool = false) async -> UIImage {
        let targetSize: CGSize
        if maintainAspectRatio {
            let aspectRatio = image.size.width / image.size.height
            if size.width / size.height > aspectRatio {
                targetSize = CGSize(width: size.height * aspectRatio, height: size.height)
            } else {
                targetSize = CGSize(width: size.width, height: size.width / aspectRatio)
            }
        } else {
            targetSize = size
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private func saveImage(_ image: UIImage, to url: URL) throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw UGCError.imageProcessingFailed
        }
        try data.write(to: url)
    }

    // MARK: - File Management

    func getImage(for puzzle: UGCPuzzle) -> UIImage? {
        let cacheKey = NSString(string: "main:\(puzzle.imageAssetPath)")
        if let cached = imageCache.object(forKey: cacheKey) { return cached }
        
        let imagePath = ugcDirectory.appendingPathComponent(puzzle.imageAssetPath)
        guard let img = UIImage(contentsOfFile: imagePath.path) else { return nil }
        imageCache.setObject(img, forKey: cacheKey)
        return img
    }

    func getThumbnail(for puzzle: UGCPuzzle) -> UIImage? {
        let cacheKey = NSString(string: "thumb:\(puzzle.thumbnailPath)")
        if let cached = imageCache.object(forKey: cacheKey) { return cached }
        
        let thumbnailPath = ugcDirectory.appendingPathComponent(puzzle.thumbnailPath)
        guard let img = UIImage(contentsOfFile: thumbnailPath.path) else { return nil }
        imageCache.setObject(img, forKey: cacheKey)
        return img
    }
    
    /// 为“游戏棋盘尺寸”生成降采样图（显著减少每块拼图的缩放/裁切成本）
    func getBoardSizedImage(for puzzle: UGCPuzzle, maxPixelSide: CGFloat) -> UIImage? {
        let key = NSString(string: "board:\(puzzle.id.uuidString):\(Int(maxPixelSide))")
        if let cached = imageCache.object(forKey: key) { return cached }
        guard let full = getImage(for: puzzle) else { return nil }
        
        let maxSide = maxPixelSide
        guard maxSide > 0 else { return full }
        
        let src = full.size
        let srcMax = max(src.width, src.height)
        if srcMax <= maxSide {
            imageCache.setObject(full, forKey: key)
            return full
        }
        
        let ratio = maxSide / srcMax
        let newSize = CGSize(width: max(1, src.width * ratio), height: max(1, src.height * ratio))
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let scaled = renderer.image { _ in
            full.draw(in: CGRect(origin: .zero, size: newSize))
        }
        imageCache.setObject(scaled, forKey: key)
        return scaled
    }

    // MARK: - Persistence

    private func loadUGCPuzzles() {
        let plistPath = ugcDirectory.appendingPathComponent("ugc_puzzles.plist")

        guard let data = try? Data(contentsOf: plistPath),
              let puzzles = try? PropertyListDecoder().decode([UGCPuzzle].self, from: data) else {
            return
        }

        ugcPuzzles = puzzles
    }

    private func saveUGCPuzzles() {
        let plistPath = ugcDirectory.appendingPathComponent("ugc_puzzles.plist")

        guard let data = try? PropertyListEncoder().encode(ugcPuzzles) else {
            return
        }

        try? data.write(to: plistPath)
    }

    // MARK: - Storage Info

    var usedStorageSpace: Int64 {
        let enumerator = fileManager.enumerator(at: ugcDirectory, includingPropertiesForKeys: [.fileSizeKey])
        var totalSize: Int64 = 0

        while let url = enumerator?.nextObject() as? URL {
            guard let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey]),
                  let size = resourceValues.fileSize else {
                continue
            }
            totalSize += Int64(size)
        }

        return totalSize
    }

    func clearCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: ugcDirectory, includingPropertiesForKeys: nil)
        for url in contents where url.lastPathComponent != "ugc_puzzles.plist" {
            try fileManager.removeItem(at: url)
        }
        imageCache.removeAllObjects()
    }
}

// MARK: - Errors
enum UGCError: Error {
    case imageProcessingFailed
    case storageFull
    case invalidImage
}

// MARK: - UGC Progress Management
extension UGCManager {
    func saveProgress(_ progress: UGCProgress) {
        let key = "ugc_progress_\(progress.puzzleId.uuidString)"

        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func getProgress(for puzzleId: UUID) -> UGCProgress {
        let key = "ugc_progress_\(puzzleId.uuidString)"

        guard let data = UserDefaults.standard.data(forKey: key),
              let progress = try? JSONDecoder().decode(UGCProgress.self, from: data) else {
            return UGCProgress(puzzleId: puzzleId)
        }

        return progress
    }

    func deleteProgress(for puzzleId: UUID) {
        let key = "ugc_progress_\(puzzleId.uuidString)"
        UserDefaults.standard.removeObject(forKey: key)
    }
}
