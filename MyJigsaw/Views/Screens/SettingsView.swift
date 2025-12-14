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
        }
    }
}

#Preview {
    SettingsView()
}
