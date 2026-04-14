//
//  SoundManager.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/20.
//

import Foundation
import AVFoundation
import UIKit

class SoundManager {
    static let shared = SoundManager()

    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isSoundEnabled = true

    private init() {
        setupAudioPlayers()
    }

    private func setupAudioPlayers() {
        // 设置音频会话
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ 设置音频会话失败: \(error.localizedDescription)")
        }

        // 从 Assets.xcassets 的 .dataset 加载音频
        loadSound(assetName: "jigsaw sound", forKey: "jigsaw")
        loadSound(assetName: "succeed", forKey: "succeed")
        loadSound(assetName: "achievement", forKey: "achievement")
    }

    private func loadSound(assetName: String, forKey key: String) {
        guard let asset = NSDataAsset(name: assetName) else {
            print("❌ 找不到音频资产: \(assetName)")
            return
        }

        do {
            let player = try AVAudioPlayer(data: asset.data)
            player.prepareToPlay()
            audioPlayers[key] = player
            print("✅ 成功加载音频: \(assetName)")
        } catch {
            print("❌ 加载音频失败 \(assetName): \(error.localizedDescription)")
        }
    }

    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
    }

    func playJigsawSound() {
        playSound(forKey: "jigsaw")
    }

    func playSucceedSound() {
        playSound(forKey: "succeed")
    }

    func playAchievementSound() {
        playSound(forKey: "achievement")
    }

    private func playSound(forKey key: String) {
        guard isSoundEnabled else { return }

        guard let player = audioPlayers[key] else {
            print("❌ 音频播放器不存在: \(key)")
            return
        }

        // 如果正在播放，先停止
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }

        player.play()
    }
}
