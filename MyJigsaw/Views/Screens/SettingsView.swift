//
//  SettingsView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var persistenceManager = PersistenceManager.shared
    @StateObject private var achievementCenter = AchievementCenter.shared

    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // Game Settings Section
                Section("游戏设置") {
                    Toggle("音效", isOn: $settingsManager.appSettings.soundEnabled)
                    Toggle("触感反馈", isOn: $settingsManager.appSettings.hapticsEnabled)
                    Toggle("计时器", isOn: $settingsManager.appSettings.timerEnabled)
                }
                
                // Accessibility Section
                Section("辅助功能") {
                    Toggle("显示网格辅助线", isOn: $settingsManager.appSettings.showGuideOverlay)
                    Toggle("减少动态效果", isOn: $settingsManager.appSettings.reduceMotionOverride)
                }
                
                // Data Management Section
                Section("数据管理") {
                    Toggle("启用调试模式", isOn: .constant(false))
                        .onChange(of: false) { oldValue, newValue in
                            // 这里可以设置调试模式，但现在先保持false
                        }

                    Button(action: {
                        testPersistence()
                    }) {
                        HStack {
                            Text("测试持久化")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                        }
                    }

                    Button(action: {
                        showResetAlert = true
                    }) {
                        HStack {
                            Text("重置所有数据")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }

                // About Section
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link("隐私政策", destination: URL(string: "https://example.com/privacy")!)
                    Link("用户协议", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("重置所有数据", isPresented: $showResetAlert) {
                Button("取消", role: .cancel) { }
                Button("重置", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("这将清除所有通关记录、成就进度和解锁状态。应用将回到初始状态。此操作无法撤销。")
            }
        }
    }

    private func testPersistence() {
        print("🧪 开始测试持久化功能")

        // 创建一个测试进度
        let testLevelId = UUID()
        print("🆔 测试关卡ID: \(testLevelId)")

        // 保存测试进度
        persistenceManager.saveGameProgress(levelStableId: "test_level", isCompleted: true, time: 120.5, moves: 50)

        // 立即加载并检查
        let loadedProgress = persistenceManager.getGameProgress(forStableId: "test_level")
        print("🔍 加载的进度: isCompleted=\(loadedProgress.isCompleted), bestTime=\(String(describing: loadedProgress.bestTime)), bestMoves=\(String(describing: loadedProgress.bestMoves))")

        // 再次检查所有进度
        let allProgress = persistenceManager.getAllProgress()
        print("📊 总进度记录数: \(allProgress.count)")

        for progress in allProgress {
            if progress.isCompleted {
                print("✅ 已完成的关卡: \(progress.levelStableId)")
            }
        }

        print("🧪 持久化测试完成")
    }

    private func resetAllData() {
        persistenceManager.resetAllData()
        achievementCenter.resetAchievements()
        dismiss()
    }
}

#Preview {
    SettingsView()
}
