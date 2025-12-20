//
//  ContentView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI

struct ContentView: View {
    @State private var isActive = false
    @StateObject private var achievementCenter = AchievementCenter.shared
    @State private var showingAchievementUnlock = false
    // // 在ContentView的init中添加：
    // init() {
    //     for family in UIFont.familyNames.sorted() {
    //         let names = UIFont.fontNames(forFamilyName: family)
    //         print("字体家族：\(family)，包含字体：\(names)")
    //     }
    // }
    var body: some View {
        ZStack {
            if isActive {
                HomeView()
                    .transition(.opacity) // 淡入淡出效果
            } else {
                SplashScreenView()
            }

            // 成就解锁反馈
            if showingAchievementUnlock, let achievement = achievementCenter.newlyUnlockedAchievement {
                AchievementUnlockToast(achievement: achievement)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        // 3秒后自动隐藏
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation {
                                showingAchievementUnlock = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            // 应用启动时评估所有成就状态
            achievementCenter.evaluateAllAchievements()

            // 调试：检查持久化数据
            //let persistenceManager = PersistenceManager.shared
            //let allProgress = persistenceManager.getAllProgress()
            //print("🚀 应用启动 - 已加载关卡进度: \(allProgress.count) 条记录")
            // for progress in allProgress where progress.isCompleted {
            //     print("   ✅ 关卡 \(progress.levelStableId) 已完成")
            // }

            // 3秒后跳转
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
        .onChange(of: achievementCenter.newlyUnlockedAchievement) { oldValue, newValue in
            if newValue != nil {
                // 播放成就解锁音效
                SoundManager.shared.playAchievementSound()

                withAnimation {
                    showingAchievementUnlock = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
