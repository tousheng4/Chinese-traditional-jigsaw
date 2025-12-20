//
//  SettingsManager.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var appSettings: AppSettings {
        didSet {
            saveSettings()
            updateSoundManager()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private enum Keys {
        static let appSettings = "app_settings"
    }
    
    private init() {
        self.appSettings = Self.loadSettings()
        updateSoundManager()
    }
    
    // MARK: - Settings Management
    private static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: Keys.appSettings),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
    
    private func saveSettings() {
        if let data = try? encoder.encode(appSettings) {
            userDefaults.set(data, forKey: Keys.appSettings)
        }
    }

    private func updateSoundManager() {
        SoundManager.shared.setSoundEnabled(appSettings.soundEnabled)
    }
    
    // MARK: - Convenience Methods
    func toggleSound() {
        appSettings.soundEnabled.toggle()
    }
    
    func toggleHaptics() {
        appSettings.hapticsEnabled.toggle()
    }
    
    func toggleGuideOverlay() {
        appSettings.showGuideOverlay.toggle()
    }
    
    func toggleReduceMotion() {
        appSettings.reduceMotionOverride.toggle()
    }
    
    func toggleTimer() {
        appSettings.timerEnabled.toggle()
    }
}
