//
//  ContentView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI

struct ContentView: View {
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive {
                HomeView()
                    .transition(.opacity) // 淡入淡出效果
            } else {
                SplashScreenView()
            }
        }
        .onAppear {
            // 3秒后跳转
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
