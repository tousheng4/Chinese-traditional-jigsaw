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

        // 加载音频文件
        loadSound(fileName: "jigsaw sound.mp3", forKey: "jigsaw")
        loadSound(fileName: "succeed.mp3", forKey: "succeed")
        loadSound(fileName: "achievement.mp3", forKey: "achievement")
    }

    private func loadSound(fileName: String, forKey key: String) {
        // 从主bundle加载音频文件
        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("❌ 找不到音频文件: \(fileName)")
            print("   搜索路径: \(Bundle.main.bundlePath)")

            // 列出bundle中的所有mp3文件用于调试
            if let bundlePath = Bundle.main.resourcePath {
                let fm = FileManager.default
                if let files = try? fm.contentsOfDirectory(atPath: bundlePath) {
                    let mp3Files = files.filter { $0.hasSuffix(".mp3") }
                    print("   Bundle中的MP3文件: \(mp3Files)")
                }
            }
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[key] = player
            print("✅ 成功加载音频: \(fileName)")
        } catch {
            print("❌ 加载音频失败 \(fileName): \(error.localizedDescription)")
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
