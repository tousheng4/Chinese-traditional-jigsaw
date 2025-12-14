//
//  SplashScreenView.swift
//  MyJigsaw
//
//  Created by Allegre7tto on 2025/12/14.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var opacity = 0.0
    @State private var scale = 0.8
    
    var body: some View {
        ZStack {
            // 背景色 - 使用米白色/宣纸色，体现传统质感
            Color(red: 0.98, green: 0.97, blue: 0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 图标/Logo区域
                ZStack {
                    // 装饰性背景圆
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "puzzlepiece.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.red) // 传统朱红色
                }
                
                // 标题
                VStack(spacing: 8) {
                    Text("MyJigsaw")
                        .font(.system(size: 40, weight: .bold, design: .serif))
                        .foregroundColor(.black.opacity(0.8))
                    
                    Text("传统文化拼图")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .tracking(2) // 增加字间距
                }
                
                // Slogan
                Text("指尖上的传统艺术")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.top, 40)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                opacity = 1.0
                scale = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

