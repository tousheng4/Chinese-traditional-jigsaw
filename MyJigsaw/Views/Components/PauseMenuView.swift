//
//  PauseMenuView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI

struct PauseMenuView: View {
    @Binding var isShowing: Bool
    let onResume: () -> Void
    let onRestart: () -> Void
    let onQuit: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Title
                Text("游戏暂停")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Menu options
                VStack(spacing: 16) {
                    Button(action: {
                        isShowing = false
                        onResume()
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            Text("继续游戏")
                                .font(.headline)
                        }
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        isShowing = false
                        onRestart()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                            Text("重新开始")
                                .font(.headline)
                        }
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        isShowing = false
                        onQuit()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                            Text("退出游戏")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PauseMenuView(
        isShowing: .constant(true),
        onResume: {},
        onRestart: {},
        onQuit: {}
    )
}
